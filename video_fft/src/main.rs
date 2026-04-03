use mimalloc::MiMalloc;

#[global_allocator]
static GLOBAL: MiMalloc = MiMalloc;

mod export;
mod videofft;
mod videofftstats;
mod videofn;
mod videoview;

use anyhow::Context;
use rayon::prelude::*;
use tch::IndexOp;

const USE_GPU: bool = true;

pub struct infer_results {
    p_calm: f32,
    p_contraversial: f32,
    p_rd: f32,
}

pub struct infer_slave {
    slave: *mut ::std::os::raw::c_void,
    batch_size: ::std::os::raw::c_uchar,
}

impl Drop for infer_slave {
    fn drop(&mut self) {
        unsafe { export::delete_infer_slave(self.slave) };
    }
}

impl infer_slave {
    pub fn new(batch_size: u8) -> Self {
        Self {
            slave: unsafe { export::new_infer_slave(batch_size) },
            batch_size: batch_size,
        }
    }

    pub fn infer(&mut self, vals: Vec<videofft::fft_video>) -> anyhow::Result<Vec<infer_results>> {
        if (vals.len() % (self.batch_size as usize)) != 0 {
            return Err(anyhow::format_err!(
                "The input vector length should be a multiple of batch size"
            ));
        }

        let ret = Vec::<infer_results>::with_capacity(vals.len());
        for i in (vals.chunks(self.batch_size as usize)) {}

        return Ok(ret);
    }
}

fn video_tensor_2_fft_file_160(
    tensor_video_input: tch::Tensor,
    path_dir_output: &str,
) -> anyhow::Result<String> {
    let total_video_length = tensor_video_input.size()[0];

    if total_video_length < 120 {
        return Err(anyhow::format_err!("Video too short..."));
    } else {
        std::fs::create_dir_all(path_dir_output)?;

        let use_gpu: bool = USE_GPU && tch::Cuda::is_available();

        if (120 <= total_video_length) && (total_video_length < 176) {
            let path_file_video_bin_output: String = path_dir_output.to_string() + "/out-1.bin";

            if !std::fs::exists(path_file_video_bin_output.as_str())? {
                videofft::fft_video::from_torch_video_tensor(
                    /*tensor_video_input: &tch::Tensor =*/
                    &tensor_video_input.i((0..total_video_length, .., .., ..)),
                    use_gpu,
                )?
                .save(path_file_video_bin_output.as_str())?;
            }

            return Ok("Successfully encoded the the whole video into a single file".to_string());
        } else {
            let float_val = (((total_video_length - 160) as f32) / 40.0) as f32;

            let diff = float_val - float_val.floor();

            let num_windows: i64 = {
                if diff < 0.25 {
                    (float_val.floor() as i64) + 1
                } else {
                    (float_val.ceil() as i64) + 1
                }
            };

            for i in 1..=num_windows {
                let path_file_video_bin_output: String =
                    path_dir_output.to_string() + "/out-" + i.to_string().as_str() + ".bin";

                if !std::fs::exists(path_file_video_bin_output.as_str())? {
                    let end = (((total_video_length - 160) * (i - 1)) / (num_windows - 1)) + 160;
                    let start = end - 160;

                    videofft::fft_video::from_torch_video_tensor(
                        /*tensor_video_input: &tch::Tensor =*/
                        &tensor_video_input.i((start..end, .., .., ..)),
                        use_gpu,
                    )?
                    .save(path_file_video_bin_output.as_str())?;
                }
            }

            return Ok("Successfully encoded the video into many pieces".to_string());
        }
    }
}

fn process_video_file(path_file_video_input: String) -> anyhow::Result<String> {
    let res = videoview::video_slicer::new(path_file_video_input.clone(), None, 8.0, 1280, 720, 3)?;
    let full_tensor = res.get_video_tensor()?;

    let path_dir_output = path_file_video_input + ".dir";

    return video_tensor_2_fft_file_160(
        /*tensor_video_input: tch::Tensor =*/ full_tensor,
        /*path_dir_output: &str =*/ path_dir_output.as_str(),
    );
}

fn fft_all_video_files_under_dir(target_dir: &str) -> anyhow::Result<()> {
    let mut list_path_file_video: Vec<String> = vec![];

    for entry in jwalk::WalkDir::new(target_dir)
        .into_iter()
        .filter_map(|e| e.ok())
    {
        let path = entry.path();

        if !path.is_dir() {
            if let Some(ext) = path.extension() {
                if ext == "mp4" {
                    list_path_file_video.push(path.display().to_string());
                }
            }
        }
    }

    let pool = rayon::ThreadPoolBuilder::new()
        .num_threads(8)
        .build()
        .unwrap();

    let processed: Vec<anyhow::Result<String>> = pool.install(|| {
        list_path_file_video
            .into_par_iter() // Convert to a parallel iterator
            .map(process_video_file) // The function to map   |s| s.to_uppercase()
            .collect() // Gather back into a Vec
    });

    return Ok(());
}

fn main() -> anyhow::Result<()> {
    let args: Vec<String> = std::env::args().collect();

    match args.len() {
        0 => {
            eprintln!("Usage: <self> <s/f> <directory>");
            eprintln!("s: stats for bin files under <directory>");
            eprintln!("f: perform fft compression for videos under <directory>");
            return Err(anyhow::format_err!("Wrong invocation"));
        }

        1 => {
            eprintln!("Usage: {} <s/f> <directory>", args[0]);
            eprintln!("s: stats for bin files under <directory>");
            eprintln!("f: perform fft compression for videos under <directory>");
            return Err(anyhow::format_err!("Wrong invocation"));
        }

        2 => {
            eprintln!("Usage: {} <s/f> <directory>", args[0]);
            eprintln!("s: stats for bin files under <directory>");
            eprintln!("f: perform fft compression for videos under <directory>");
            return Err(anyhow::format_err!("Wrong invocation"));
        }

        3 => {
            match args[1].as_str() {
                "s" => {
                    videofftstats::eval_mean_sigma(args[2].as_str())?;
                    return Ok(());
                }
                "f" => {
                    fft_all_video_files_under_dir(/*target_dir: &str =*/ args[2].as_str())?;
                    return Ok(());
                }
                _ => {
                    eprintln!("Usage: {} <s/f> <directory>", args[0]);
                    eprintln!("s: stats for bin files under <directory>");
                    eprintln!("f: perform fft compression for videos under <directory>");
                    return Err(anyhow::format_err!("Wrong invocation"));
                }
            };
        }

        _ => {
            eprintln!("Spurious arguments detected");
            eprintln!("Usage: {} <s/f> <directory>", args[0]);
            eprintln!("s: stats for bin files under <directory>");
            eprintln!("f: perform fft compression for videos under <directory>");
            return Err(anyhow::format_err!("Wrong invocation"));
        }
    };

    return Ok(());
}
