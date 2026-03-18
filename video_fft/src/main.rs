use anyhow::Context;
use tch::IndexOp;

fn convert_encoded_video_to_raw(
    path_file_video_input: &str,
    path_file_video_output: &str,
    fps: f32,
    size_x: u16,
    size_y: u16,
    size_c: u8,
) -> anyhow::Result<()> {
    assert!(
        size_c == 3,
        "Currently only implemented for 3 channel color videos..."
    );

    if std::fs::exists(path_file_video_output)? {
        eprintln!("Not running ffmpeg, output file already exists.");
        return Ok(());
    }

    let res = std::process::Command::new("ffmpeg")
        .args([
            "-i",
            path_file_video_input,
            "-r",
            fps.to_string().as_str(),
            "-nostdin",
            "-f",
            "rawvideo",
            "-pix_fmt",
            "rgb24",
            "-vf",
            ("scale=".to_string()
                + size_x.to_string().as_str()
                + ":"
                + size_y.to_string().as_str())
            .as_str(),
            path_file_video_output,
        ])
        .status()?;

    match res.code() {
        None => {
            return Err(anyhow::format_err!("FFmpeg failed with unknown error"));
        }
        Some(e) => {
            if e == 0 {
                return Ok(());
            } else {
                return Err(anyhow::format_err!("FFmpeg failed with error code {}", e));
            }
        }
    };
}

fn get_file_hash(path_file_input: &str) -> anyhow::Result<u64> {
    let file: std::fs::File = std::fs::File::open(path_file_input)?;
    let mmap: memmap2::Mmap = unsafe { memmap2::Mmap::map(&file).expect("failed to map the file") };
    Ok(gxhash::gxhash64(&mmap, 12345))
}

fn do_pad_video(tensor_video: &tch::Tensor) -> anyhow::Result<tch::Tensor> {
    let size: Vec<i64> = tensor_video.size();
    let (_b, h, w, _c) = (size[0], size[1], size[2], size[3]);

    let padded: tch::Tensor = if h < w {
        tensor_video.f_pad(&[0, 0, 0, 0, 0, w - h], "constant", 0.0)?
    } else if w < h {
        tensor_video.f_pad(&[0, 0, 0, h - w, 0, 0], "constant", 0.0)?
    } else {
        tensor_video.shallow_clone()
    };

    Ok(padded)
}

pub fn compress_video_tensor(
    tensor_video: &tch::Tensor,
    fps: f64,
    freq_limit: f64,
) -> anyhow::Result<tch::Tensor> {
    let tensor_video_pad: tch::Tensor = do_pad_video(tensor_video)?;

    let tensor_video_permuted: tch::Tensor =
        tensor_video_pad.permute(/*dims =*/ &[3, 1, 2, 0]);

    let n_dim3: i64 = tensor_video_permuted.size()[3];
    let freq_step: f64 = fps / (n_dim3 as f64);

    let mut n: i64 = 0;
    for i in 0..=(n_dim3 / 2) {
        if ((i as f64) * freq_step) < freq_limit {
            n += 1;
        } else {
            break;
        }
    }

    let tensor_video_fft: tch::Tensor = tensor_video_permuted.fft_rfftn(
        /*s =*/ tensor_video_permuted.size(),
        /*dim =*/ vec![0, 1, 2, 3],
        /*norm =*/ "forward",
    );

    let tensor_video_fft: tch::Tensor =
        tensor_video_fft.narrow(/*dim =*/ 3, /*start =*/ 0, /*length =*/ n);

    let tensor_video_fft: tch::Tensor = tensor_video_fft.fft_fftshift(/*dim =*/ vec![0, 1, 2]);

    let space_length: i64 = tensor_video_permuted.size()[2];
    let truncated_size: i64 = space_length >> 3;
    let size_start: i64 = (space_length - truncated_size) >> 1;
    let size_end: i64 = size_start + truncated_size;

    let compressed_fft: tch::Tensor =
        tensor_video_fft.i(
            /*index =*/ (.., size_start..size_end, size_start..size_end, ..),
        );

    let abs: tch::Tensor = compressed_fft.abs();
    let angle: tch::Tensor = compressed_fft.angle();
    let cat_fft: tch::Tensor = tch::Tensor::cat(&[abs, angle], 0);

    let input_for_interp: tch::Tensor = cat_fft.unsqueeze(0);

    let interpolated: tch::Tensor = input_for_interp.f_upsample_trilinear3d(
        &[truncated_size, truncated_size, 60 as i64],
        false, // align_corners
        None,  // scale_h (optional)
        None,  // scale_w (optional)
        None,  // scale_d (optional)
    )?;

    return Ok(interpolated.squeeze());
}

struct video_slicer {
    path_file_video_input: String,
    path_file_rawvideo_output: String,

    fps: f32,

    size_x: u16,
    size_y: u16,
    size_c: u8,
    size_t: u16,

    dist_x: usize,
    dist_y: usize,
    dist_c: usize,
    dist_t: usize,

    mmap: memmap2::Mmap,
}

impl Drop for video_slicer {
    fn drop(&mut self) {
        let _ = std::fs::remove_file(self.path_file_rawvideo_output.as_str());
    }
}

impl video_slicer {
    fn new(
        path_file_video_input: String,
        mut path_file_rawvideo_output: Option<String>,
        fps: f32,
        size_x: u16,
        size_y: u16,
        size_c: u8,
    ) -> anyhow::Result<Self> {
        if path_file_rawvideo_output.is_none() {
            let hash: u64 = get_file_hash(&path_file_video_input)?;
            path_file_rawvideo_output = Some(format!("{}.{:x}.raw", path_file_video_input, hash));
        }

        let path_file_rawvideo_output: String = path_file_rawvideo_output.unwrap();

        convert_encoded_video_to_raw(
            path_file_video_input.as_str(),
            path_file_rawvideo_output.as_str(),
            fps,
            size_x,
            size_y,
            size_c,
        )?;

        let file: std::fs::File = std::fs::File::open(path_file_rawvideo_output.as_str())?;
        let mmap: memmap2::Mmap =
            unsafe { memmap2::Mmap::map(&file).expect("failed to map the file") };

        let size_t: u16 =
            (mmap.len() / ((size_x as usize) * (size_y as usize) * (size_c as usize))) as u16;

        let dist_c: i32 = 1;

        let dist_c: usize = 1;
        let dist_x: usize = dist_c * (size_c as usize);
        let dist_y: usize = dist_x * (size_x as usize);
        let dist_t: usize = dist_y * (size_y as usize);

        let ret: Self = Self {
            path_file_video_input: path_file_video_input,
            path_file_rawvideo_output: path_file_rawvideo_output,
            fps: fps,

            size_x: size_x,
            size_y: size_y,
            size_c: size_c,
            size_t: size_t,

            dist_x: dist_x,
            dist_y: dist_y,
            dist_c: dist_c,
            dist_t: dist_t,

            mmap: mmap,
        };

        return Ok(ret);
    }

    #[inline(always)]
    fn get_size(&self, i: u8) -> usize {
        match i {
            0 => self.size_c as usize,
            1 => self.size_x as usize,
            2 => self.size_y as usize,
            3 => self.size_t as usize,
            _ => 1 as usize,
        }
    }

    #[inline(always)]
    fn get_dist(&self, i: u8) -> usize {
        match i {
            0 => self.dist_c,
            1 => self.dist_x,
            2 => self.dist_y,
            3 => self.dist_t,
            _ => self.mmap.len(),
        }
    }

    fn get_video_tensor(&self) -> anyhow::Result<tch::Tensor> {
        if self.size_t < 2 {
            return Err(anyhow::format_err!("The video blob seems too small"));
        }

        let sizes: [i64; 4] = [
            self.get_size(3) as i64,
            self.get_size(2) as i64,
            self.get_size(1) as i64,
            self.get_size(0) as i64,
        ];

        let dists: [i64; 4] = [
            self.get_dist(3) as i64,
            self.get_dist(2) as i64,
            self.get_dist(1) as i64,
            self.get_dist(0) as i64,
        ];

        println!("{:?}", dists);

        let tensor_data: tch::Tensor = unsafe {
            tch::Tensor::from_blob(
                self.mmap.as_ptr(),
                &sizes,
                &dists,
                tch::Kind::Uint8,
                tch::Device::Cpu,
            )
        };

        return Ok(tensor_data);
    }
}

#[repr(C)]
#[derive(Debug)]
struct a_t {
    t: [f32; 60],
}

#[repr(C)]
#[derive(Debug)]
struct a_x {
    x: [a_t; 160],
}

#[repr(C)]
#[derive(Debug)]
struct a_y {
    y: [a_x; 160],
}

#[repr(C)]
#[derive(Debug)]
struct a_p {
    p: [a_y; 6],
}

impl a_p {
    fn from_torch_fft_tensor(
        tensor_fft_input: &tch::Tensor,
    ) -> anyhow::Result<std::sync::Arc<Self>> {
        if tensor_fft_input.kind() != tch::Kind::Float {
            anyhow::bail!(
                "Input tensor must be Kind::Float, found {:?}",
                tensor_fft_input.kind()
            );
        }

        const expected_size: usize = 6 * 160 * 160 * 60;
        let actual_size = tensor_fft_input.numel();
        if actual_size != expected_size {
            anyhow::bail!(
                "Tensor size mismatch: expected {} elements, found {}",
                expected_size,
                actual_size
            );
        }

        let mut store: std::sync::Arc<std::mem::MaybeUninit<Self>> = std::sync::Arc::new_uninit();

        /* Do the init */
        {
            let ptr: *mut Self = std::sync::Arc::<std::mem::MaybeUninit<Self>>::get_mut(&mut store)
                .context("Failed to obtain unique mutable access to the newly allocated Arc")?
                .as_mut_ptr();

            const shape: [i64; 4] = [6, 160, 160, 60];
            const strides: [i64; 4] = [160 * 160 * 60, 160 * 60, 60, 1];

            /* Now initialize the tensors */
            {
                let mut out_tensor: tch::Tensor = unsafe {
                    tch::Tensor::from_blob(
                        ptr as *mut u8,
                        &shape,
                        &strides,
                        tch::Kind::Float,
                        tch::Device::Cpu,
                    )
                };

                out_tensor.copy_(&tensor_fft_input);
            }
        }

        let final_video: std::sync::Arc<Self> = unsafe { store.assume_init() };

        return Ok(final_video);
    }
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let res = video_slicer::new("./video.mp4".to_string(), None, 8.0, 1280, 720, 3)?;
    let full_tensor = res.get_video_tensor()?;

    let sliced_tensor = full_tensor.i((0..80, .., .., ..));

    let compressed_tensor = compress_video_tensor(
        /*tensor_video: &tch::Tensor =*/ &sliced_tensor,
        /*fps: f64 =*/ 8.0,
        /*freq_limit: f64 =*/ 3.0,
    )?;

    let blob = a_p::from_torch_fft_tensor(&compressed_tensor)?;

    println!("{:?}", blob);

    Ok(())
}
