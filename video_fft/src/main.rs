use std::num::IntErrorKind;

async fn read_video(path_file_video_input: String) -> anyhow::Result<()> {
    let path_dir_images_output = path_file_video_input.clone() + ".dir";
    tokio::fs::create_dir_all(path_dir_images_output.as_str()).await?;
    let res = tokio::process::Command::new("ffmpeg")
        .args([
            "-i",
            path_file_video_input.as_str(),
            "-r",
            "8",
            "-vf",
            "scale=1280:720",
            (path_dir_images_output.clone() + "/out-%6d.bmp").as_str(),
        ])
        .status()
        .await;

    println!(" #### Return status {:?} ####", res);

    for entry in glob::glob((path_dir_images_output.clone() + "/out-*.bmp").as_str())
        .expect("Failed to read glob pattern")
    {
        match entry {
            Ok(path) => {
                println!("{:?}", path.display());
                tokio::fs::remove_file(path.as_path()).await?;
            }
            Err(e) => println!("{:?}", e),
        }
    }

    tokio::fs::remove_dir_all((path_dir_images_output.clone() + "/out-*.bmp").as_str()).await;

    Ok(())
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let _ = read_video("./video.mp4".to_string()).await;
    Ok(())
}
