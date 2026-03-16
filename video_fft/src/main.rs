use tch::IndexOp;

async fn convert_encoded_video_to_raw(
    path_file_video_input: &str,
    path_file_video_output: &str,
    fps: f32,
    size_x: u32,
    size_y: u32,
) -> anyhow::Result<()> {
    if !tokio::fs::try_exists(path_file_video_output).await? {
        let res = tokio::process::Command::new("ffmpeg")
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
            .status()
            .await?;

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
    } else {
        eprintln!("Not running ffmpeg, output file already exists.");
        return Ok(());
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
        size_x,
        size_y,
    )
    .await?;

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
    read_video_to_torch("./video.mp4".to_string(), 8 as f32, 1280, 720).await?;
    Ok(())
}
