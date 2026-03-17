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
    let file = std::fs::File::open(path_file_input)?;
    let mmap = unsafe { memmap2::Mmap::map(&file).expect("failed to map the file") };
    Ok(gxhash::gxhash64(&mmap, 12345))
}

fn do_pad_video(tensor_video: &tch::Tensor) -> anyhow::Result<tch::Tensor> {
    let size = tensor_video.size();
    let (_b, h, w, _c) = (size[0], size[1], size[2], size[3]);

    let padded = if h < w {
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
    // 1. Padding
    let tensor_video_pad: tch::Tensor = do_pad_video(tensor_video)?;

    // 2. Permute: (B, H, W, C) -> (C, H, W, B)
    let tensor_video_permuted: tch::Tensor =
        tensor_video_pad.permute(/*dims =*/ &[3, 1, 2, 0]);

    // 3. FFT Logic
    // PyTorch rfftfreq equivalent:
    // freq = [0, 1, ..., n/2] / (n * d)
    let n_dim3: i64 = tensor_video_permuted.size()[3];
    let freq_step: f64 = fps / (n_dim3 as f64);

    // Calculate 'n' based on FREQ_LIMIT
    let mut n: i64 = 0;
    for i in 0..=(n_dim3 / 2) {
        if ((i as f64) * freq_step) < freq_limit {
            n += 1;
        } else {
            break;
        }
    }

    // Perform the FFT
    let tensor_video_fft = tensor_video_permuted.fft_rfftn(
        /*s =*/ tensor_video_permuted.size(),
        /*dim =*/ tensor_video_permuted.size(),
        /*norm =*/ "forward",
    );

    // Truncate the time axis
    let tensor_video_fft: tch::Tensor =
        tensor_video_fft.narrow(/*dim =*/ 3, /*start =*/ 0, /*length =*/ n);

    // Shift the space fft
    let tensor_video_fft: tch::Tensor = tensor_video_fft.fft_fftshift(/*dim =*/ vec![0, 1, 2]);

    // Calculate truncating of spacial indices
    let space_length: i64 = tensor_video_permuted.size()[2];
    let truncated_size: i64 = space_length >> 3;
    let size_start: i64 = (space_length - truncated_size) >> 1;
    let size_end: i64 = size_start + truncated_size;

    // 6. Spatial Truncation
    let compressed_fft: tch::Tensor =
        tensor_video_fft.i(
            /*index =*/ (.., size_start..size_end, size_start..size_end, ..),
        );

    // 7. Magnitude and Phase Concatenation
    let abs = compressed_fft.abs();
    let angle = compressed_fft.angle();
    let cat_fft = tch::Tensor::cat(&[abs, angle], 0);

    // 8. Trilinear Interpolation
    // interpolate expects (Batch, Channels, Depth, Height, Width)
    // We add a batch dimension with unsqueeze(0)
    let input_for_interp = cat_fft.unsqueeze(0);

    // Interpolate the tensor to fixed size
    let interpolated = input_for_interp.f_upsample_trilinear3d(
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
            let hash = get_file_hash(&path_file_video_input)?;
            path_file_rawvideo_output = Some(format!("{}.{:x}.raw", path_file_video_input, hash));
        }

        let path_file_rawvideo_output = path_file_rawvideo_output.unwrap();

        convert_encoded_video_to_raw(
            path_file_video_input.as_str(),
            path_file_rawvideo_output.as_str(),
            fps,
            size_x,
            size_y,
            size_c,
        )?;

        let file = std::fs::File::open(path_file_rawvideo_output.as_str())?;
        let mmap = unsafe { memmap2::Mmap::map(&file).expect("failed to map the file") };
        let size_t =
            (mmap.len() / ((size_x as usize) * (size_y as usize) * (size_c as usize))) as u16;

        let dist_c = 1;

        let dist_c: usize = 1;
        let dist_x: usize = size_c as usize;
        let dist_y: usize = (dist_x as usize) * (size_x as usize);
        let dist_t: usize = (dist_y as usize) * (size_y as usize);

        return Ok(Self {
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
        });
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

        let mut dists: [i64; 4] = [
            self.get_dist(3) as i64,
            self.get_dist(2) as i64,
            self.get_dist(1) as i64,
            self.get_dist(0) as i64,
        ];

        println!("{:?}", dists);

        let tensor_data = unsafe {
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

async fn read_video_to_torch(
    path_file_video_input: String,
    fps: f32,
    size_x: u32,
    size_y: u32,
) -> anyhow::Result<tch::Tensor> {
    let path_file_video_output = path_file_video_input.clone() + ".raw";

    convert_encoded_video_to_raw(
        path_file_video_input.as_str(),
        path_file_video_output.as_str(),
        fps,
        size_x as u16,
        size_y as u16,
        3,
    )?;

    let file = std::fs::File::open(path_file_video_output.as_str())?;
    let mmap = unsafe { memmap2::Mmap::map(&file).expect("failed to map the file") };
    let frame_size = (size_x * size_y * 3) as usize;
    let total_bytes = mmap.len();
    let num_frames = total_bytes / frame_size;

    if num_frames >= 1 {
        println!("Num frames = {:?}", num_frames);

        let tensor_data = unsafe {
            tch::Tensor::from_blob(
                mmap.as_ptr(),
                &[num_frames as i64, size_y as i64, size_x as i64, 3 as i64],
                &[
                    (size_x * size_x * 3) as i64,
                    (size_x * 3) as i64,
                    3 as i64,
                    1 as i64,
                ],
                tch::Kind::Uint8,
                tch::Device::Cpu,
            )
        };

        let video_data_permuted = tch::Tensor::permute(&tensor_data, vec![3, 1, 2, 0]);

        let sliced_tensor = video_data_permuted.i((.., .., .., 0..160));

        println!("Final data {:?}", sliced_tensor.size());

        return Ok(sliced_tensor);
    } else {
        return Err(anyhow::format_err!("The video blob seems too small"));
    }
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let res = video_slicer::new("./video.mp4".to_string(), None, 8.0, 1280, 720, 3)?;
    let _ = res.get_video_tensor();
    Ok(())
}
