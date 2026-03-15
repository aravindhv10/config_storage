async fn read_video(path_file_video_input: String) -> anyhow::Result<()> {
    let buffer = tokio::fs::read(path_file_video_input).await?;
    let reader = std::io::Cursor::new(buffer);
    let mut ictx = ffmpeg_next::format::io::input(reader).unwrap();

    Ok(())
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    ffmpeg_next::init().unwrap();
    let _ = read_video("./video.mp4".to_string()).await;
    Ok(())
}
