async fn read_video(path_file_video_input: String) -> anyhow::Result<()> {
    let path_dir_images_output = path_file_video_input.clone() + ".dir";
    tokio::fs::create_dir_all(path_dir_images_output.as_str()).await?;
    let res = tokio::process::Command::new("ffmpeg")
        .args([
            "-i",
            path_file_video_input.as_str(),
            "-r",
            "8",
            (path_dir_images_output + "/out-%6d.bmp").as_str(),
        ])
        .spawn();

    Ok(())
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let _ = read_video("./video.mp4".to_string()).await;
    Ok(())
}
