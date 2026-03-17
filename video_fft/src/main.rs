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

struct video_slicer {
    path_file_video_input: String,
    path_file_rawvideo_output: String,
    fps: f32,
    size_x: u16,
    size_y: u16,
    size_c: u8,
    size_t: u16,
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
            path_file_rawvideo_output = Some(format!("{}.{}.raw", path_file_video_input, hash));
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

        return Ok(Self {
            path_file_video_input: path_file_video_input,
            path_file_rawvideo_output: path_file_rawvideo_output,
            fps: fps,
            size_x: size_x,
            size_y: size_y,
            size_c: size_c,
            size_t: size_t,
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
        (0..i).map(|idx| self.get_size(idx)).product()
    }

    fn get_video_tensor(&mut self) -> anyhow::Result<tch::Tensor> {
        if self.size_t < 2 {
            return Err(anyhow::format_err!("The video blob seems too small"));
        }

        let tensor_data = unsafe {
            tch::Tensor::from_blob(
                self.mmap.as_ptr(),
                &[
                    self.get_size(3) as i64,
                    self.get_size(2) as i64,
                    self.get_size(1) as i64,
                    self.get_size(0) as i64,
                ],
                &[
                    self.get_dist(3) as i64,
                    self.get_dist(2) as i64,
                    self.get_dist(1) as i64,
                    self.get_dist(0) as i64,
                ],
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
    Ok(())
}
