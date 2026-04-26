use std::io::{Read, Write};

pub fn convert_encoded_video_to_raw(
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

pub fn get_file_hash(path_file_input: &str) -> anyhow::Result<u64> {
    let file: std::fs::File = std::fs::File::open(path_file_input)?;
    let input: memmap2::Mmap = unsafe { memmap2::Mmap::map(&file) }?;
    Ok(gxhash::gxhash64(&input, /* seed = */ 12345))
}

pub fn get_str_hash(path_file_input: &str) -> u64 {
    gxhash::gxhash64(
        /* input = */ path_file_input.as_bytes(),
        /* seed = */ 12345,
    )
}

pub fn convert_encoded_video_to_raw_piped(
    input_buffer: Vec<u8>,
    fps: f32,
    size_x: u16,
    size_y: u16,
    size_c: u8,
) -> anyhow::Result<Vec<u8>> {

    assert!(
        size_c == 3,
        "Currently only implemented for 3 channel color videos..."
    );

    let mut child = std::process::Command::new("ffmpeg")
        .args([
            "-i", "pipe:0",
            "-r", fps.to_string().as_str(),
            "-f", "rawvideo",
            "-pix_fmt", "rgb24",
            "-vf", format!("scale={}:{}", size_x, size_y).as_str(),
            "pipe:1",
        ])
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .spawn()?;

    if let Some(mut stdin) = child.stdin.take() {
        stdin.write_all(&input_buffer)?;
    }

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
        return Err(anyhow::format_err!("FFmpeg failed: {}", err_msg));
    }

    Ok(output_buffer)
}
