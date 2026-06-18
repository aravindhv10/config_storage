#[global_allocator]
static GLOBAL: mimalloc::MiMalloc = mimalloc::MiMalloc;

mod export;
mod hasher;
mod inferencerelated;
mod inferencerelatedimage;
mod lockssync;
mod serverinferencechannel;
mod serverinferencechannelboth;
mod serverinferencechannelimage;
mod videofft;
mod videofftstats;
mod videofn;
mod videoview;

use anyhow::Context;
use rayon::prelude::*;
use tch::IndexOp;
// use log::{info, trace, warn};

pub mod infer {
    tonic::include_proto!("myrdvideoinferinfer");

    pub(crate) const FILE_DESCRIPTOR_SET: &[u8] = tonic::include_file_descriptor_set!("infer");
}

const USE_GPU: bool = true;

struct grpc_inferer {
    infpair: std::sync::Arc<serverinferencechannelboth::combined_infer>,
    semaphore: std::sync::Arc<tokio::sync::Semaphore>,
}

impl grpc_inferer {
    fn new() -> Self {
        let ret = Self {
            infpair: std::sync::Arc::<serverinferencechannelboth::combined_infer>::new(
                serverinferencechannelboth::combined_infer::new(),
            ),
            semaphore: std::sync::Arc::new(tokio::sync::Semaphore::new(6)),
        };
        return ret;
    }
}

#[tonic::async_trait]
impl infer::rdvideoinfer_server::Rdvideoinfer for grpc_inferer {
    async fn doinfer(
        &self,
        request: tonic::Request<infer::Grpcvideodata>,
    ) -> std::result::Result<tonic::Response<infer::Grpcvideopredictionreply>, tonic::Status> {
        tracing::info!("Received an inference request");
        let path_dir_prefix = std::path::PathBuf::from("/dev/shm/RD/video");

        let _ = tokio::fs::create_dir_all(&path_dir_prefix).await?;

        let video_data = &(request.into_inner().data);

        let hash = hasher::blob_hash::new_from_slice(video_data.as_slice());

        let hash_string = hash.get_hash_string();
        tracing::info!("Hash of received video {}", hash_string);

        let path_file_video_output = path_dir_prefix.join(hash_string);

        if (tokio::fs::try_exists(&path_file_video_output).await?) {
            tracing::error!("File already exists {:?}", path_file_video_output);
            return Err(tonic::Status::internal(
                "Same file is already being processed...",
            ));
        } else {
            let _ = tokio::fs::write(&path_file_video_output, video_data).await?;

            let infpair = self.infpair.clone();

            let path_file_video_output_tmp = path_file_video_output.clone();

            let _permit = self
                .semaphore
                .acquire()
                .await
                .map_err(|_| tonic::Status::internal("Semaphore closed unexpectedly"))?;

            let res = tokio::task::spawn_blocking(move || {
                infpair.do_infer_on_video_file(&path_file_video_output_tmp)
            })
            .await
            .expect("The blocking task panicked");

            match res {
                Ok(o) => {
                    let preds: Vec<infer::Grpcvideoprediction> =
                        o.0.iter()
                            .map(|i| infer::Grpcvideoprediction {
                                pa: i.p_calm,
                                pb: i.p_contraversial,
                                pc: i.p_rd,
                            })
                            .collect();

                    let avg =
                        o.0.iter().map(|i| i.majority() as f32).sum::<f32>() / (o.0.len() as f32);

                    let bed_scaling_factor: f32 =
                        o.1.iter().map(|x| x.bed_status()).sum::<f32>() / (o.1.len() as f32);

                    let imgpreds: Vec<infer::Grpcimgprediction> =
                        o.1.into_iter()
                            .map(|i| infer::Grpcimgprediction {
                                arm: i.ARM as u32,
                                rail: i.RAIL as u32,
                                leg: i.LEG as u32,
                                pos: i.POS as u32,
                                bed: i.BED as u32,
                            })
                            .collect();

                    return Ok(tonic::Response::new(infer::Grpcvideopredictionreply {
                        preds: preds,
                        majority: avg * bed_scaling_factor,
                        imgpreds: imgpreds,
                    }));
                }
                Err(e) => {
                    return Err(tonic::Status::internal("Internal error, inference failed"));
                }
            }
        }

        Err(tonic::Status::ok("Done inference"))
    }
}

fn main() -> anyhow::Result<()> {
    // tracing_subscriber::fmt()
    //         .with_writer(std::io::stderr)
    //         .with_max_level(tracing::Level::INFO)
    //         .init();

    tracing_subscriber::fmt()
        .with_writer(std::io::stderr)
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .init();

    unsafe { export::locker_to_inference_mode() };

    let ip_v4 = std::net::IpAddr::V4(std::net::Ipv4Addr::new(0, 0, 0, 0));
    let port: u16 = 8001;
    let addr = std::net::SocketAddr::new(ip_v4, port);

    let rt = tokio::runtime::Builder::new_multi_thread()
        .thread_stack_size(1 << 28)
        .enable_all()
        .build()
        .unwrap();

    let service = tonic_reflection::server::Builder::configure()
        .register_encoded_file_descriptor_set(infer::FILE_DESCRIPTOR_SET)
        .build_v1()
        .unwrap();

    // rt.block_on(async {
    //     println!("Server attempting to bind to {}", addr);
    //     let result = tonic::transport::Server::builder()
    //         .max_concurrent_streams(Some(4))
    //         .add_service(service)
    //         .add_service(
    //             infer::rdvideoinfer_server::RdvideoinferServer::new(grpc_inferer::new())
    //                 .max_encoding_message_size(1 << 25)
    //                 .max_decoding_message_size(1 << 25),
    //         )
    //         .serve(addr)
    //         .await;

    //     if let Err(e) = result {
    //         eprintln!("Server exited with error: {}", e);
    //     }
    // });

    rt.block_on(async {
        tracing::warn!("Server attempting to bind to {}", addr);
        let result = tonic::transport::Server::builder()
            .add_service(service)
            .add_service(
                infer::rdvideoinfer_server::RdvideoinferServer::new(grpc_inferer::new())
                    .max_encoding_message_size(1 << 26)
                    .max_decoding_message_size(1 << 26),
            )
            .serve(addr)
            .await;

        if let Err(e) = result {
            tracing::error!("Server exited with error: {}", e);
        }
    });

    Ok(())
}
