#[global_allocator]
static GLOBAL: mimalloc::MiMalloc = mimalloc::MiMalloc;

mod export;
mod filestore;
mod hasher;
mod inferencerelated;
mod inferencerelatedimage;
mod keyvaluedb;
mod mlockffmpeg;
mod serverinferencechannel;
mod serverinferencechannelboth;
mod serverinferencechannelimage;
mod version;
mod videofft;
mod videofftstats;
mod videofn;
mod videoview;

use futures::StreamExt;
use prost::Message;
use rayon::prelude::*;

use redb::ReadableDatabase;
use redb::TableDefinition;

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
                    match rep.vidver {
                        Some(o) => {
                            if (version::major_version() == o.major)
                                && (version::minor_version() == o.minor)
                            {
                                return Ok(rep);
                            } else {
                                tracing::warn!(
                                    "Cached version is different from current version, not using"
                                );
                                return Err(anyhow::format_err!(
                                    "Cached version is different from current version, not using"
                                ));
                            }
                        }
                        None => {
                            tracing::warn!("Cached results version too old");
                            return Err(anyhow::format_err!("Cached results version too old"));
                        }
                    }
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

fn get_current_time() -> u64 {
    match std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH) {
        Ok(o) => {
            return o.as_secs();
        }
        Err(_e) => {
            return 1782492853;
        }
    }
}

struct grpc_inferer {
    infpair: std::sync::Arc<serverinferencechannelboth::combined_infer>,
    semaphore: std::sync::Arc<tokio::sync::Semaphore>,
    cachedb: Option<std::sync::Arc<keyvaluedb::key_value_db>>,
    filestore: filestore::file_store,
}

impl grpc_inferer {
    async fn new() -> anyhow::Result<Self> {
        let filestore = filestore::file_store::new()
            .await
            .expect("Failed to construct filestore within grpc inferer");

        let cachedb = keyvaluedb::key_value_db::new("/root/.cache/infdb.fjall");

        let ret = Self {
            infpair: std::sync::Arc::<serverinferencechannelboth::combined_infer>::new(
                serverinferencechannelboth::combined_infer::new().await?,
            ),
            semaphore: std::sync::Arc::new(tokio::sync::Semaphore::new(16)),
            cachedb: cachedb.ok(),
            filestore: filestore,
        };

        Ok(ret)
    }

    async fn doinfer_on_file(&self, hash: hasher::blob_hash) -> anyhow::Result<()> {
        let hash = std::sync::Arc::new(hash);

        tracing::info!("Got video with hash {}", hash.get_hash_string());

        match &self.cachedb {
            None => {
                return Err(anyhow::format_err!(
                    "No db connection found, cant write inference results"
                ));
            }
            Some(maindbconnection) => {
                let res = {
                    let tmphash = hash.clone();
                    let tmpcache = maindbconnection.clone();
                    tokio::task::spawn_blocking(move || {
                        tmpcache.get_Grpcvideopredictionreply(tmphash.as_ref())
                    })
                    .await?
                };

                match res {
                    Ok(_i) => {
                        tracing::warn!(
                            "inference results for {} already found in cache, not doing anything.",
                            hash.get_hash_string()
                        );
                        return Ok(());
                    }
                    Err(_e) => {
                        tracing::info!(
                            "correct inference results for {} not found, running inference.",
                            hash.get_hash_string()
                        );

                        tracing::info!(
                            "number of permits remaining so far {}",
                            self.semaphore.available_permits()
                        );

                        let res = {
                            tracing::info!(
                                "Acquiring tokio async Semaphore for {}",
                                hash.get_hash_string()
                            );

                            let infpair = self.infpair.clone();

                            let _path_file_video_output =
                                self.filestore.get_path_video(/*key =*/ &hash);

                            let _permit = self.semaphore.acquire().await.map_err(|_| {
                                tonic::Status::internal("Semaphore closed unexpectedly")
                            })?;

                            let res = infpair.do_infer_on_video_file(&hash).await;

                            res
                        };

                        tracing::info!("Inference completed for hash {}", hash.get_hash_string());

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

                                let vidver = infer::Version {
                                    major: version::major_version(),
                                    minor: version::minor_version(),
                                    patch: version::patch_version(),
                                };

                                let ret = infer::Grpcvideopredictionreply {
                                    preds: preds,
                                    majority: avg * bed_scaling_factor,
                                    imgpreds: imgpreds,
                                    vidver: Some(vidver),
                                    videohash: hash.get_hash().to_vec(),
                                    timestamp: get_current_time(),
                                };

                                match maindbconnection
                                    .put_Grpcvideopredictionreply(hash.as_ref(), &ret)
                                {
                                    Ok(_o) => {
                                        tracing::info!(
                                            "Successfully wrote inference results for {} into cache.",
                                            hash.get_hash_string()
                                        );
                                    }
                                    Err(e) => {
                                        tracing::error!(
                                            "Failed to write inference results for {} to cache due to {}.",
                                            hash.get_hash_string(),
                                            e
                                        );
                                    }
                                };

                                tracing::info!(
                                    "Done inferring for hash {}",
                                    hash.get_hash_string()
                                );

                                return Ok(());
                            }
                            Err(e) => {
                                tracing::error!(
                                    "Inference failed for {} with error {}",
                                    hash.get_hash_string(),
                                    e
                                );
                                return Err(anyhow::format_err!(
                                    "Inference failed for {} with error {}",
                                    hash.get_hash_string(),
                                    e
                                ));
                            }
                        }
                    }
                }
            }
        };
    }

    async fn infer_on_all_stale_files(&self) -> anyhow::Result<()> {
        tracing::warn!("Checking stale files to infer");
        let currentfiles = filestore::file_store::new()
            .await?
            .get_all_files_with_hash()
            .await
            .into_iter()
            .map(|(h, _p)| self.doinfer_on_file(h));

        let _ = futures::stream::iter(currentfiles)
            .buffer_unordered(8)
            .collect::<Vec<_>>()
            .await;

        Ok(())
    }
}

#[tonic::async_trait]
impl infer::rdvideoinfer_server::Rdvideoinfer for grpc_inferer {
    async fn doinfer(
        &self,
        request: tonic::Request<infer::Grpcvideodata>,
    ) -> std::result::Result<tonic::Response<infer::Grpcvideopredictionreply>, tonic::Status> {
        tracing::info!("Received an inference request");

        let video_data = &(request.into_inner().data);

        let hash = std::sync::Arc::new(hasher::blob_hash::new_from_slice(video_data.as_slice()));

        tracing::info!("Got video with hash {}", hash.get_hash_string());

        match &self.cachedb {
            None => {
                tracing::warn!(
                    "No caching db found, skipping cache loopup step for {}",
                    hash.get_hash_string()
                );
            }
            Some(maincache) => {
                let res = {
                    let tmpcache = maincache.clone();
                    let tmphash = hash.clone();
                    let res = tokio::task::spawn_blocking(move || {
                        tmpcache.get_Grpcvideopredictionreply(tmphash.as_ref())
                    })
                    .await;

                    match res {
                        Ok(o) => o,
                        Err(_e) => Err(anyhow::format_err!("join error")),
                    }
                };

                match res {
                    Ok(o) => {
                        tracing::warn!(
                            "inference results for {} found in cache, returning it.",
                            hash.get_hash_string()
                        );
                        return Ok(tonic::Response::new(o));
                    }
                    Err(_e) => {
                        tracing::info!(
                            "correct inference results for {} not found in cache, proceeding for inference.",
                            hash.get_hash_string()
                        );
                    }
                };
            }
        };

        tracing::info!(
            "number of permits remaining so far {}",
            self.semaphore.available_permits()
        );

        let res = {
            tracing::info!("Acquiring Queue Semaphore for {}", hash.get_hash_string());

            let _permit = self
                .semaphore
                .acquire()
                .await
                .map_err(|_| tonic::Status::internal("Semaphore closed unexpectedly"))?;

            let _path_file_video_output = match self
                .filestore
                .put_content(/*key =*/ &hash, /*value =*/ video_data)
                .await
            {
                Ok(o) => o,
                Err(_e) => {
                    return Err(tonic::Status::internal(
                        "Failed to write the video file, CPU RAM full",
                    ));
                }
            };

            self.infpair.do_infer_on_video_file(&hash).await
        };

        tracing::info!("Inference completed for hash {}", hash.get_hash_string());

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

                let vidver = infer::Version {
                    major: version::major_version(),
                    minor: version::minor_version(),
                    patch: version::patch_version(),
                };

                let ret = infer::Grpcvideopredictionreply {
                    preds: preds,
                    majority: avg * bed_scaling_factor,
                    imgpreds: imgpreds,
                    vidver: Some(vidver),
                    videohash: hash.get_hash().to_vec(),
                    timestamp: get_current_time(),
                };

                match &self.cachedb {
                    None => {
                        tracing::warn!("No cache db connection found, not writing to db");
                    }
                    Some(o) => {
                        match o.put_Grpcvideopredictionreply(&hash, &ret) {
                            Ok(_) => {
                                tracing::info!(
                                    "Wrote results for {} to cache.",
                                    hash.get_hash_string()
                                );
                            }
                            Err(e) => {
                                tracing::error!(
                                    "Failed to write inference results for {} to cache.",
                                    hash.get_hash_string()
                                );
                            }
                        };
                    }
                }

                tracing::info!("Sending reply for hash {}", hash.get_hash_string());
                return Ok(tonic::Response::new(ret));
            }
            Err(e) => {
                tracing::error!(
                    "Inference failed for {} with error {}",
                    hash.get_hash_string(),
                    e
                );

                return Err(tonic::Status::internal(format!(
                    "Internal error, inference failed due to {}",
                    e
                )));
            }
        }
    }
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt()
        .with_writer(std::io::stderr)
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .init();

    unsafe { export::locker_to_inference_mode() };

    let ip_v4 = std::net::IpAddr::V4(std::net::Ipv4Addr::new(0, 0, 0, 0));
    let port: u16 = 8001;
    let addr = std::net::SocketAddr::new(ip_v4, port);

    let service = tonic_reflection::server::Builder::configure()
        .register_encoded_file_descriptor_set(infer::FILE_DESCRIPTOR_SET)
        .build_v1()
        .unwrap();

    tracing::warn!("Server attempting to bind to {}", addr);

    let slave = grpc_inferer::new().await?;
    let _ = slave.infer_on_all_stale_files().await;

    let _result = tonic::transport::Server::builder()
        .add_service(service)
        .add_service(
            infer::rdvideoinfer_server::RdvideoinferServer::new(slave)
                .max_encoding_message_size(1 << 26)
                .max_decoding_message_size(1 << 26),
        )
        .serve(addr)
        .await?;

    Ok(())
}
