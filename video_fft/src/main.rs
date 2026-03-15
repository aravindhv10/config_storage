async fn read_video(path_file_video_input: String) -> anyhow::Result<()> {
    Ok(())
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    ffmpeg::init().unwrap();
    let _ = read_video("./video.mp4".to_string()).await;
    Ok(())
}
