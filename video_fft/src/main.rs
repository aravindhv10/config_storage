use ndarray::Array3;
use std::io::Cursor;
use video_rs::{self, Decoder, Options, Receiver};

async fn read_video(path_file_video_input: String) -> anyhow::Result<()> {
    let buffer = tokio::fs::read(path_file_video_input).await?;

    video_rs::init().unwrap();
    let source = Cursor::new(buffer);

    Ok(())
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let _ = read_video("./video.mp4".to_string()).await;
    Ok(())
}
