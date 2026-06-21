#[global_allocator]
static GLOBAL: mimalloc::MiMalloc = mimalloc::MiMalloc;

mod export;
mod hasher;
mod inferencerelated;
mod inferencerelatedimage;
mod serverinferencechannel;
mod serverinferencechannelboth;
mod serverinferencechannelimage;
mod videofft;
mod videofftstats;
mod videofn;
mod videoview;

use prost::Message;
use rayon::prelude::*;

use anyhow::Context;
use redb::Database;
use redb::Error;
use redb::ReadableDatabase;
use redb::TableDefinition;
use tch::IndexOp;

use crate::infer::Grpcvideopredictionreply;

pub mod infer {
    tonic::include_proto!("myrdvideoinferinfer");

    pub(crate) const FILE_DESCRIPTOR_SET: &[u8] = tonic::include_file_descriptor_set!("infer");
}

const USE_GPU: bool = true;
const TABLE: TableDefinition<&[u8], &[u8]> = TableDefinition::new("inference_data");

fn read_from_db_slave(
    key: &[u8],
    db: std::sync::Arc<Option<redb::Database>>,
) -> anyhow::Result<Grpcvideopredictionreply> {
    match db.as_ref() {
        Some(o) => {
            match o.begin_read()?.open_table(TABLE)?.get(key)? {
                Some(val) => {
                    let rep = Grpcvideopredictionreply::decode(val.value())?;
                    return Ok(rep);
                }
                None => {
                    return Err(anyhow::format_err!("Value not found"));
                }
            };
        }
        None => {
            return Err(anyhow::format_err!("No DB connection found"));
        }
    };
}

async fn read_from_db(
    key: std::sync::Arc<hasher::blob_hash>,
    db: std::sync::Arc<Option<redb::Database>>,
) -> anyhow::Result<Grpcvideopredictionreply> {
    tokio::task::spawn_blocking(move || read_from_db_slave(key.get_hash(), db))
        .await
        .expect("The spawned process panicked")
}

fn write_to_db_slave(
    key: &[u8],
    value: Vec<u8>,
    db: std::sync::Arc<Option<redb::Database>>,
) -> anyhow::Result<()> {
    match db.as_ref() {
        Some(o) => match o.begin_write() {
            Ok(write_txn) => {
                write_txn.open_table(TABLE)?.insert(key, value.as_slice())?;
                write_txn.commit()?;
                return Ok(());
            }
            Err(e) => {
                return Err(anyhow::format_err!(
                    "Failed to write to database due to {}",
                    e
                ));
            }
        },
        None => {
            return Err(anyhow::format_err!("No connection to db found."));
        }
    }
}

async fn write_to_db(
    key: std::sync::Arc<hasher::blob_hash>,
    inference_results: &Grpcvideopredictionreply,
    db: std::sync::Arc<Option<redb::Database>>,
) -> anyhow::Result<()> {
    let mut buf: Vec<u8> = Vec::with_capacity(inference_results.encoded_len());
    inference_results.encode(&mut buf)?;
    tokio::task::spawn_blocking(move || write_to_db_slave(key.get_hash(), buf, db))
        .await
        .expect("Failed to join in write_to_db")
}

struct grpc_inferer {
    infpair: std::sync::Arc<serverinferencechannelboth::combined_infer>,
    semaphore: std::sync::Arc<tokio::sync::Semaphore>,
    cachedb: std::sync::Arc<Option<redb::Database>>,
}

impl grpc_inferer {
    fn new() -> Self {
        let ret = Self {
            infpair: std::sync::Arc::<serverinferencechannelboth::combined_infer>::new(
                serverinferencechannelboth::combined_infer::new(),
            ),
            semaphore: std::sync::Arc::new(tokio::sync::Semaphore::new(6)),
            cachedb: std::sync::Arc::new(Database::create("/root/.cache/infdb.redb").ok()),
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

        let hash = std::sync::Arc::new(hasher::blob_hash::new_from_slice(video_data.as_slice()));

        let hash_string = hash.get_hash_string();

        tracing::info!("Got video with hash {}", &hash_string);

        match read_from_db(hash.clone(), self.cachedb.clone()).await {
            Ok(ret) => {
                tracing::warn!(
                    "Results for {} found in cache, returning cached results.",
                    &hash_string
                );
                return Ok(tonic::Response::new(ret));
            }
            Err(e) => {
                tracing::info!(
                    "inference results for {} not found. proceeding to run inference.",
                    hash_string
                )
            }
        };

        let path_file_video_output = path_dir_prefix.join(hash_string.clone());

        if (tokio::fs::try_exists(&path_file_video_output).await?) {
            tracing::error!("File already exists {:?}", path_file_video_output);
            return Err(tonic::Status::internal(
                "Same file is already being processed...",
            ));
        } else {
            let _ = tokio::fs::write(&path_file_video_output, video_data).await?;

            let infpair = self.infpair.clone();

            let path_file_video_output_tmp = path_file_video_output.clone();

            tracing::info!("Acquiring GPU Semaphore for {}", &hash_string);
            let permit = self
                .semaphore
                .acquire()
                .await
                .map_err(|_| tonic::Status::internal("Semaphore closed unexpectedly"))?;

            tracing::info!(
                "number of permits remaining so far {}",
                self.semaphore.available_permits()
            );

            let res = tokio::task::spawn_blocking(move || {
                infpair.do_infer_on_video_file(&path_file_video_output_tmp)
            })
            .await
            .expect("The blocking task panicked");
            tracing::info!("Inference completed for hash {}", &hash_string);

            match res {
                Ok(o) => {
                    let preds: Vec<infer::Grpcvideoprediction> = o
                        .results_video
                        .iter()
                        .map(|i| infer::Grpcvideoprediction {
                            pa: i.p_calm,
                            pb: i.p_contraversial,
                            pc: i.p_rd,
                        })
                        .collect();

                    let avg = o
                        .results_video
                        .iter()
                        .map(|i| i.majority() as f32)
                        .sum::<f32>()
                        / (o.results_video.len() as f32);

                    let bed_scaling_factor: f32 =
                        o.results_image.iter().map(|x| x.bed_status()).sum::<f32>()
                            / (o.results_image.len() as f32);

                    let imgpreds: Vec<infer::Grpcimgprediction> = o
                        .results_image
                        .into_iter()
                        .map(|i| infer::Grpcimgprediction {
                            arm: i.ARM as u32,
                            rail: i.RAIL as u32,
                            leg: i.LEG as u32,
                            pos: i.POS as u32,
                            bed: i.BED as u32,
                        })
                        .collect();

                    let ret = infer::Grpcvideopredictionreply {
                        preds: preds,
                        majority: avg * bed_scaling_factor,
                        imgpreds: imgpreds,
                    };

                    match write_to_db(hash, &ret, self.cachedb.clone()).await {
                        Ok(_) => {
                            tracing::info!("Added inference results of {} to cache.", &hash_string);
                        }
                        Err(e) => {
                            tracing::error!("Failed to cache results for {}.", &hash_string);
                        }
                    };

                    tracing::info!("Sending reply for hash {}", &hash_string);
                    return Ok(tonic::Response::new(ret));
                }
                Err(e) => {
                    tracing::error!("Inference failed for {} with error {}", &hash_string, e);
                    return Err(tonic::Status::internal("Internal error, inference failed"));
                }
            }
        }

        Err(tonic::Status::ok("Done inference"))
    }
}

fn main() -> anyhow::Result<()> {
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
