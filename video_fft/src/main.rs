use std::num::IntErrorKind;

async fn video_2_images(path_file_video_input: String) -> Vec<String> {
    Vec![]
}

async fn read_video_to_images(path_file_video_input: String) -> anyhow::Result<()> {
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

async fn read_video_to_raw(
    path_file_video_input: String,
    fps: f32,
    size_x: u32,
    size_y: u32,
) -> anyhow::Result<()> {
    let path_file_video_output = path_file_video_input.clone() + ".raw";
    let res = tokio::process::Command::new("ffmpeg")
        .args([
            "-i",
            path_file_video_input.as_str(),
            "-r",
            "{fps}",
            "-f",
            "rawvideo",
            "-pix_fmt",
            "rgb24",
            "-vf",
            "scale=1280:720",
            path_file_video_output.as_str(),
        ])
        .status()
        .await;

    Ok(())
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let _ = read_video_to_raw("./video.mp4".to_string()).await;
    Ok(())
}
