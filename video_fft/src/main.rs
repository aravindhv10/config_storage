async fn read_video_to_raw(
    path_file_video_input: String,
    fps: f32,
    size_x: u32,
    size_y: u32,
) -> anyhow::Result<()> {
    let path_file_video_output = path_file_video_input.clone() + ".raw";
    if !tokio::fs::try_exists(path_file_video_output.as_str()).await? {
        let res = tokio::process::Command::new("ffmpeg")
            .args([
                "-i",
                path_file_video_input.as_str(),
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
                path_file_video_output.as_str(),
            ])
            .status()
            .await?;

        match res.code() {
            None => {
                return Err(anyhow::format_err!("FFmpeg failed with unknown error"));
            }
            Some(e) => {
                return Err(anyhow::format_err!("FFmpeg failed with error code {}", e));
            }
        };
    } else {
        eprintln!("Not running ffmpeg, output file already exists.");
    }

    let file =
        std::fs::File::open(path_file_video_output.as_str()).expect("failed to open the file");

    let mmap = unsafe { memmap2::Mmap::map(&file).expect("failed to map the file") };

    let frame_size = (size_x * size_y * 3) as usize;
    let total_bytes = mmap.len();
    let num_frames = total_bytes / frame_size;
    print!("Num frames = {:?}", num_frames);

    let video_array = ndarray::ArrayView4::from_shape(
        (num_frames, size_y as usize, size_x as usize, 3),
        &mmap[..num_frames * frame_size],
    )?;

    println!("Array shape: {:?}", video_array.shape());

    Ok(())
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    read_video_to_raw("./video.mp4".to_string(), 8 as f32, 1280, 720).await?;
    Ok(())
}
