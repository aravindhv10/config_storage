use mimalloc::MiMalloc;

#[global_allocator]
static GLOBAL: MiMalloc = MiMalloc;

mod export;
mod videofft;
mod videofftstats;
mod videofn;
mod videoview;

use anyhow::Context;
use bytemuck::Contiguous;
use bytemuck::Pod;
use bytemuck::Zeroable;
use rayon::prelude::*;
use tch::IndexOp;

const USE_GPU: bool = true;

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

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let args: Vec<String> = std::env::args().collect();

    if args.len() < 2 {
        eprintln!("Usage: {} <directory>", args[0]);
        std::process::exit(1);
    }

    let target_dir = args[1].to_string();

    if true {
        videofftstats::eval_mean(target_dir.as_str()).await?;
    } else {
        tokio::task::spawn_blocking(move || {
            fft_all_video_files_under_dir(/*target_dir: &str =*/ target_dir.as_str())
        })
        .await?;
    }

    Ok(())
}
