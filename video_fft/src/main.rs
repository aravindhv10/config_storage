#[global_allocator]
static GLOBAL: mimalloc::MiMalloc = mimalloc::MiMalloc;

mod export;
mod filestore;
mod hasher;
mod inferencerelated;
mod inferencerelatedimage;
mod videofft;
mod videofftstats;
mod videofn;
mod videoview;

use futures::StreamExt;
use rayon::prelude::*;

const USE_GPU: bool = true;
const IMAGE_INFERENCE_BATCH_SIZE: i64 = 16;

async fn infer_video_end_2_end(
    key: hasher::blob_hash,
    use_gpu: bool,
) -> anyhow::Result<Vec<inferencerelated::infer_results>> {
    let filestore = filestore::file_store::new().await?;

    let raw_tensor = filestore
        .get_raw_tensor(
            &key, /*fps=*/ 8 as f32, /*size_x=*/ 1280, /*size_y=*/ 720,
        )
        .await?;

    let slicer = videoview::video_slicer_mapped::new(
        /*mmap =*/ raw_tensor, /*fps =*/ 8 as f32, /*size_x =*/ 1280,
        /*size_y =*/ 720, /*size_c =*/ 3,
    )?;

    let video_tensor = slicer.get_video_tensor()?;

    let size = video_tensor.size(); // B H W C

    {
        let image_indices: std::vec::Vec<i64> = (0..16)
            .map(|x: i64| (size[0] * x) / (IMAGE_INFERENCE_BATCH_SIZE - 1))
            .collect();

        let image_indices_tensor = tch::Tensor::from_slice(image_indices.as_slice());

        let image_tensor =
            video_tensor.index_select(/*dim =*/ 0, /*index =*/ &image_indices_tensor);

        let mut slave = inferencerelatedimage::infer_slave::new(/*batch_size =*/ 16);
        let res = slave.infer(&image_tensor)?;
        tracing::trace!("{:?}", res);
    }

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
        tracing::trace!("{} {} {}", i.p_calm, i.p_contraversial, i.p_rd);
    }

    return Ok(ret);
}

async fn video_tensor_2_fft_file_160(
    tensor_video_input: tch::Tensor,
    path_dir_output: impl AsRef<std::path::Path>,
) -> anyhow::Result<()> {
    let total_video_length: u64 = tensor_video_input.size()[0].try_into()?;
    let num_windows = videofft::get_num_windows(total_video_length);

    if num_windows == 0 {
        return Err(anyhow::format_err!("Video too short..."));
    } else {
        tokio::fs::create_dir_all(/*path =*/ path_dir_output.as_ref()).await?;
        let use_gpu: bool = USE_GPU && tch::Cuda::is_available();

        let path_dir_output = std::sync::Arc::new(path_dir_output.as_ref().to_path_buf());

        let tensors = tokio::task::spawn_blocking(move || {
            videofft::fft_video::windowed_from_torch_video_tensor(&tensor_video_input, use_gpu)
        })
        .await??;

        let _tmp = futures::stream::iter(tensors.iter())
            .enumerate()
            .map(|(i, v)| {
                let path_output =
                    path_dir_output.join("out-".to_string() + i.to_string().as_str() + ".bin");

                async move { v.save(path_output).await }
            })
            .buffer_unordered(8)
            .collect::<Vec<_>>()
            .await
            .into_iter()
            .enumerate()
            .for_each(|(i, e)| {
                match e {
                    Ok(_o) => {}
                    Err(e) => {
                        tracing::error!("Failed to write out for index {} due to error {}", i, e);
                    }
                };
            });

        Ok(())
    }
}

async fn process_video_file(key: hasher::blob_hash) -> anyhow::Result<()> {
    let file_store = filestore::file_store::new().await?;
    let path_file_video_input = file_store.get_path(&key);
    let mut path_dir_output = path_file_video_input.clone().into_os_string();
    path_dir_output.push(".dir");

    let out_dir = std::path::PathBuf::from(path_dir_output);

    if tokio::fs::try_exists(&out_dir).await? {
        eprintln!(
            "{:?} already exists, not working on the input file {:?}",
            out_dir, path_file_video_input
        );

        return Err(anyhow::format_err!(
            "{:?} already exists, not working on the input file {:?}",
            out_dir,
            path_file_video_input
        ));
    } else {
        let mmap = file_store
            .get_raw_tensor(
                &key, /*fps =*/ 8 as f32, /*size_x =*/ 1280, /*size_y =*/ 720,
            )
            .await?;

        let res = videoview::video_slicer_mapped::new(
            mmap, /*fps =*/ 8 as f32, /*size_x =*/ 1280, /*size_y =*/ 720,
            /*size_c =*/ 3,
        )?;

        let full_tensor = res.get_video_tensor()?;

        return video_tensor_2_fft_file_160(full_tensor, out_dir).await;
    }
}

async fn fft_all_video_files_under_dir(
    target_dir: impl AsRef<std::path::Path>,
) -> anyhow::Result<()> {
    let tmp = target_dir.as_ref().to_path_buf();
    tracing::info!("START getting the list of video files in a tokio blocking env");
    let files = tokio::task::spawn_blocking(move || {
        let tmp: Vec<hasher::blob_hash> = jwalk::WalkDir::new(tmp)
            .into_iter()
            .filter_map(|e| e.ok())
            .map(|e| e.path())
            .filter(|p| !p.is_dir())
            .filter(|p| {
                if let Some(ext) = p.extension() {
                    ext == "mp4"
                } else {
                    false
                }
            })
            .map(|f| hasher::blob_hash::new_from_file(f))
            .filter_map(|e| e.ok())
            .collect();
        tmp
    })
    .await?;

    tracing::info!(
        "DONE getting the list of video files in a tokio blocking env. START processing each of the files"
    );

    futures::stream::iter(files)
        .map(|i| process_video_file(i))
        .buffer_unordered(1)
        .collect::<Vec<_>>()
        .await
        .into_iter()
        .enumerate()
        .for_each(|(i, e)| match e {
            Ok(_) => {}
            Err(e) => {
                tracing::error!("work on file at index {} failed due to {}", i, e)
            }
        });

    tracing::info!("DONE processing each of the files");

    return Ok(());
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt()
        .with_writer(std::io::stderr)
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .init();
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
                    fft_all_video_files_under_dir(/*target_dir: &str =*/ args[2].as_str()).await?;
                    return Ok(());
                }
                "i" => {
                    infer_video_end_2_end(
                        /*path_file_video_input: String =*/
                        hasher::blob_hash::new_from_file(&args[2])?,
                        /*use_gpu: bool =*/ true,
                    )
                    .await?;
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
