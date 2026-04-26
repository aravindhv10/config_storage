use mimalloc::MiMalloc;

#[global_allocator]
static GLOBAL: MiMalloc = MiMalloc;

mod export;
mod inferencerelated;
mod videofft;
mod videofftstats;
mod videofn;
mod videoview;

use anyhow::Context;
use rayon::prelude::*;
use tch::IndexOp;

const USE_GPU: bool = true;

fn infer_video_end_2_end(
    path_file_video_input: String,
    use_gpu: bool,
) -> anyhow::Result<Vec<inferencerelated::infer_results>> {
    let slicer = videoview::video_slicer::new(
        /*path_file_video_input: String =*/ path_file_video_input,
        /*mut path_file_rawvideo_output: Option<String> =*/ None,
        /*fps: f32 =*/ 8.0,
        /*size_x: u16 =*/ 1280,
        /*size_y: u16 =*/ 720,
        /*size_c: u8 =*/ 3,
    )?;

    let video_tensor = slicer.get_video_tensor()?;

    let mut list_video_fft_tensor = videofft::fft_video::windowed_from_torch_video_tensor(
        /*tensor_video_input: &tch::Tensor =*/ &video_tensor,
        /*use_gpu: bool =*/ use_gpu,
    )?;

    /* Normalize the video tensor */
    {
        let normalizer = videofftstats::fft_video_normalizer::new(
            /*path_file_bin64_mu: String =*/ "/data/input/train_mean.64bin",
            /*path_file_bin64_sigma: String =*/ "/data/input/train_sigma.64bin",
        )?;

        normalizer.normalize_vec(
            /*x: &mut Vec<videofft::fft_video> =*/ &mut list_video_fft_tensor,
        );
    }

    let mut infer_slave = inferencerelated::infer_slave::new(1);

    let ret = infer_slave.infer(
        /*vals: &mut Vec<videofft::fft_video> =*/ &mut list_video_fft_tensor,
    )?;

    for i in ret.iter() {
        println!("{} {} {}", i.p_calm, i.p_contraversial, i.p_rd);
    }

    return Ok(ret);
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
        let stride = 160 as i32;
        let threshold = ((3 * (160 + stride)) / 4) as i32;
        let use_gpu: bool = USE_GPU && tch::Cuda::is_available();

        if (120 <= total_video_length) && (total_video_length < (threshold as i64)) {
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
            let float_val = (((total_video_length - 160) as f32) / (stride as f32)) as f32;

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
        .num_threads(4)
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
            eprintln!("i: End to end file inference");
            return Err(anyhow::format_err!("Wrong invocation"));
        }

        1 => {
            eprintln!("Usage: {} <s/f> <directory>", args[0]);
            eprintln!("s: stats for bin files under <directory>");
            eprintln!("f: perform fft compression for videos under <directory>");
            eprintln!("i: End to end file inference");
            return Err(anyhow::format_err!("Wrong invocation"));
        }

        2 => {
            eprintln!("Usage: {} <s/f> <directory>", args[0]);
            eprintln!("s: stats for bin files under <directory>");
            eprintln!("f: perform fft compression for videos under <directory>");
            eprintln!("i: End to end file inference");
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
                "i" => {
                    infer_video_end_2_end(
                        /*path_file_video_input: String =*/ args[2].clone(),
                        /*use_gpu: bool =*/ true,
                    )?;
                    return Ok(());
                }
                _ => {
                    eprintln!("Usage: {} <s/f> <directory>", args[0]);
                    eprintln!("s: stats for bin files under <directory>");
                    eprintln!("f: perform fft compression for videos under <directory>");
                    eprintln!("i: End to end file inference");
                    return Err(anyhow::format_err!("Wrong invocation"));
                }
            };
        }

        _ => {
            eprintln!("Spurious arguments detected");
            eprintln!("Usage: {} <s/f> <directory>", args[0]);
            eprintln!("s: stats for bin files under <directory>");
            eprintln!("f: perform fft compression for videos under <directory>");
            eprintln!("i: End to end file inference");
            return Err(anyhow::format_err!("Wrong invocation"));
        }
    };

    return Ok(());
}
