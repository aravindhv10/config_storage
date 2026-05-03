use std::io::{Read, Write};

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
            "-vf",
            format!("fps={},scale={}:{}", fps, size_x, size_y).as_str(),
            "-nostdin",
            "-f",
            "rawvideo",
            "-pix_fmt",
            "rgb24",
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

pub fn convert_encoded_video_to_raw_piped(
    input_buffer: Vec<u8>,
    fps: f32,
    size_x: u16,
    size_y: u16,
    size_c: u8,
) -> anyhow::Result<Vec<u8>> {
    eprintln!("convert_encoded_video_to_raw_piped entered");

    assert!(
        size_c == 3,
        "Currently only implemented for 3 channel color videos..."
    );

    eprintln!(" Passed size_c check ");

    let mut child = std::process::Command::new("ffmpeg")
        .args([
            "-i",
            "pipe:0",
            "-vf",
            format!("fps={},scale={}:{}", fps, size_x, size_y).as_str(),
            "-r",
            fps.to_string().as_str(),
            "-f",
            "rawvideo",
            "-pix_fmt",
            "rgb24",
            "pipe:1",
        ])
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .spawn()?;

    eprintln!(" Spawned ffmpeg ");

    let mut output_buffer = Vec::<u8>::new();
    if let Some(mut stdin) = child.stdin.take() {
        eprintln!(" Writing the video into stdin ");

        let handle = std::thread::spawn(move || {
            stdin.write_all(&input_buffer);
        });

        eprintln!(" Forked the thread, moving to reading the data ");

        if let Some(mut stdout) = child.stdout.take() {
            eprintln!(" Reading data from stdout ");
            stdout.read_to_end(&mut output_buffer)?;
        }

        eprintln!(" Joining the thread now ");

        match handle.join() {
            Ok(_) => println!("Writer thread finished successfully"),
            Err(e) => eprintln!("Writer thread panicked: {:?}", e),
        };

        eprintln!(" Joined the thread now ");
    }

    eprintln!("Waiting for ffmpeg to return");
    let status = child.wait()?;
    eprintln!("ffmpeg returned");

    if !status.success() {
        eprintln!("Checking error status");
        let mut err_msg = String::new();
        if let Some(mut stderr) = child.stderr.take() {
            eprintln!("Checking stderr");
            stderr.read_to_string(&mut err_msg)?;
        }
        eprintln!("FFmpeg failed: {}", err_msg);
        return Err(anyhow::format_err!("FFmpeg failed: {}", err_msg));
    }

    eprintln!("Everything done, returning");
    Ok(output_buffer)
}

pub fn convert_encoded_video_to_raw_outpipe(
    path_file_video_input: &str,
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
            "-i",
            path_file_video_input,
            "-vf",
            format!("fps={},scale={}:{}", fps, size_x, size_y).as_str(),
            "-nostdin",
            "-f",
            "rawvideo",
            "-pix_fmt",
            "rgb24",
            "pipe:1",
        ])
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .spawn()?;

    let mut output_buffer = Vec::<u8>::new();

    if let Some(mut stdout) = child.stdout.take() {
        eprintln!(" Reading data from stdout ");
        stdout.read_to_end(&mut output_buffer)?;
    }

    let status = child.wait()?;

    if !status.success() {
        eprintln!("Checking error status");
        let mut err_msg = String::new();
        if let Some(mut stderr) = child.stderr.take() {
            eprintln!("Checking stderr");
            stderr.read_to_string(&mut err_msg)?;
        }
        eprintln!("FFmpeg failed: {}", err_msg);
        return Err(anyhow::format_err!("FFmpeg failed: {}", err_msg));
    }

    Ok(output_buffer)
}
