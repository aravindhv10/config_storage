use crate::hasher;
use std::io::Read;
use std::os::unix::ffi::OsStrExt;

pub fn get_file_hash(
    path_file_input: impl AsRef<std::path::Path>,
) -> anyhow::Result<hasher::blob_hash> {
    hasher::blob_hash::new_from_file(/*infilepath =*/ path_file_input)
}

pub fn get_str_hash(path_file_input: &str) -> hasher::blob_hash {
    hasher::blob_hash::new_from_slice(path_file_input.as_bytes())
}

pub fn get_path_hash(path_file_input: impl AsRef<std::path::Path>) -> hasher::blob_hash {
    hasher::blob_hash::new_from_slice(path_file_input.as_ref().as_os_str().as_bytes())
}

pub fn convert_encoded_video_to_raw(
    path_file_video_input: impl AsRef<std::path::Path>,
    path_file_video_output: impl AsRef<std::path::Path>,
    fps: f32,
    size_x: u16,
    size_y: u16,
    size_c: u8,
) -> anyhow::Result<()> {
    assert!(
        size_c == 3,
        "Currently only implemented for 3 channel color videos..."
    );

    if std::fs::exists(path_file_video_output.as_ref())? {
        tracing::warn!("Not running ffmpeg, output file already exists.");
        return Ok(());
    }

    let res = std::process::Command::new("ffmpeg")
        .arg("-i")
        .arg(path_file_video_input.as_ref())
        .arg("-vf")
        .arg(format!("fps={},scale={}:{}", fps, size_x, size_y).as_str())
        .arg("-nostdin")
        .arg("-f")
        .arg("rawvideo")
        .arg("-pix_fmt")
        .arg("rgb24")
        .arg(path_file_video_output.as_ref())
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

pub fn convert_encoded_video_to_raw_outpipe(
    path_file_video_input: impl AsRef<std::path::Path>,
    fps: f32,
    size_x: u16,
    size_y: u16,
    size_c: u8,
    clean_video: bool,
) -> anyhow::Result<Vec<u8>> {
    assert!(
        size_c == 3,
        "Currently only implemented for 3 channel color videos..."
    );

    let mut child = std::process::Command::new("ffmpeg")
        .arg("-i")
        .arg(path_file_video_input.as_ref())
        .arg("-vf")
        .arg(format!("fps={},scale={}:{}", fps, size_x, size_y).as_str())
        .arg("-nostdin")
        .arg("-f")
        .arg("rawvideo")
        .arg("-pix_fmt")
        .arg("rgb24")
        .arg("pipe:1")
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .spawn()?;

    let mut output_buffer = Vec::<u8>::new();

    if let Some(mut stdout) = child.stdout.take() {
        stdout.read_to_end(&mut output_buffer)?;
    }

    let status = child.wait()?;

    if !status.success() {
        let mut err_msg = String::new();
        if let Some(mut stderr) = child.stderr.take() {
            stderr.read_to_string(&mut err_msg)?;
        }
        tracing::error!("FFmpeg failed: {}", err_msg);
        return Err(anyhow::format_err!("FFmpeg failed: {}", err_msg));
    }

    if clean_video {
        let _ = std::fs::remove_file(path_file_video_input.as_ref());
    }

    Ok(output_buffer)
}
