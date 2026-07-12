use crate::filestore;
use crate::hasher;
use crate::inferencerelated;
use crate::videofft;
use crate::videofftstats;
use crate::videoview;

type message_output = inferencerelated::infer_results;
type message_output_sender = crossfire::oneshot::TxOneshot<message_output>;
type message_output_receiver = crossfire::oneshot::RxOneshot<message_output>;

fn get_message_output_pair() -> (message_output_sender, message_output_receiver) {
    crossfire::oneshot::oneshot::<message_output>()
}

struct message_input {
    tensor: Vec<videofft::fft_video>,
    oneshot_send_channel: Vec<message_output_sender>,
}
type message_input_receiver = crossfire::AsyncRx<crossfire::mpsc::Array<message_input>>;
type message_input_sender = crossfire::MAsyncTx<crossfire::mpsc::Array<message_input>>;

fn get_message_input_pair() -> (message_input_sender, message_input_receiver) {
    crossfire::mpsc::bounded_async::<message_input>(32)
}

fn efficient_infer(
    vals: &mut Vec<videofft::fft_video>,
) -> anyhow::Result<Vec<inferencerelated::infer_results>> {
    match vals.len() {
        0 => {
            return Err(anyhow::format_err!("Input vector is empty..."));
        }
        1 => {
            tracing::info!("Inferring for length 1");
            let mut infer_slave = inferencerelated::infer_slave::new(1);
            let ret = infer_slave.infer(/*vals: &mut Vec<videofft::fft_video> =*/ vals)?;
            return Ok(ret);
        }
        2 => {
            tracing::trace!("Inferring for length 2");
            let mut infer_slave = inferencerelated::infer_slave::new(2);
            let ret = infer_slave.infer(/*vals: &mut Vec<videofft::fft_video> =*/ vals)?;
            return Ok(ret);
        }
        3 | 6 | 9 | 15 | 18 | 21 | 27 | 30 => {
            tracing::trace!("Inferring for length 3");
            let mut infer_slave = inferencerelated::infer_slave::new(3);
            let ret = infer_slave.infer(/*vals: &mut Vec<videofft::fft_video> =*/ vals)?;
            return Ok(ret);
        }
        4 | 8 | 12 | 16 | 20 | 24 | 28 | 32 | 36 | 40 => {
            tracing::trace!("Inferring for length 4");
            let mut infer_slave = inferencerelated::infer_slave::new(4);
            let ret = infer_slave.infer(/*vals: &mut Vec<videofft::fft_video> =*/ vals)?;
            return Ok(ret);
        }
        5 => {
            tracing::trace!("Inferring for length 5");

            let split_off_point = 4 as usize;

            let mut vals_2 = vals.split_off(split_off_point);

            let mut ret = efficient_infer(vals)?;

            let mut ret_2 = efficient_infer(&mut vals_2)?;

            ret.append(&mut ret_2);

            return Ok(ret);
        }
        7 => {
            tracing::trace!("Inferring for length 7");

            let split_off_point = 4 as usize;

            let mut vals_2 = vals.split_off(split_off_point);

            let mut ret = efficient_infer(vals)?;

            let mut ret_2 = efficient_infer(&mut vals_2)?;

            ret.append(&mut ret_2);

            return Ok(ret);
        }
        10 => {
            tracing::trace!("Inferring for length 10");

            let split_off_point = 8 as usize;

            let mut vals_2 = vals.split_off(split_off_point);

            let mut ret = efficient_infer(vals)?;

            let mut ret_2 = efficient_infer(&mut vals_2)?;

            ret.append(&mut ret_2);

            return Ok(ret);
        }
        11 => {
            tracing::trace!("Inferring for length 11");

            let split_off_point = 8 as usize;

            let mut vals_2 = vals.split_off(split_off_point);

            let mut ret = efficient_infer(vals)?;

            let mut ret_2 = efficient_infer(&mut vals_2)?;

            ret.append(&mut ret_2);

            return Ok(ret);
        }
        13 => {
            tracing::trace!("Inferring for length 13");

            let split_off_point = 12 as usize;

            let mut vals_2 = vals.split_off(split_off_point);

            let mut ret = efficient_infer(vals)?;

            let mut ret_2 = efficient_infer(&mut vals_2)?;

            ret.append(&mut ret_2);

            return Ok(ret);
        }
        14 => {
            tracing::trace!("Inferring for length 14");

            let split_off_point = 12 as usize;

            let mut vals_2 = vals.split_off(split_off_point);

            let mut ret = efficient_infer(vals)?;

            let mut ret_2 = efficient_infer(&mut vals_2)?;

            ret.append(&mut ret_2);

            return Ok(ret);
        }
        17 => {
            tracing::trace!("Inferring for length 17");

            let split_off_point = 16 as usize;

            let mut vals_2 = vals.split_off(split_off_point);

            let mut ret = efficient_infer(vals)?;

            let mut ret_2 = efficient_infer(&mut vals_2)?;

            ret.append(&mut ret_2);

            return Ok(ret);
        }
        19 => {
            tracing::trace!("Inferring for length 19");

            let split_off_point = 16 as usize;

            let mut vals_2 = vals.split_off(split_off_point);

            let mut ret = efficient_infer(vals)?;

            let mut ret_2 = efficient_infer(&mut vals_2)?;

            ret.append(&mut ret_2);

            return Ok(ret);
        }
        22 => {
            tracing::trace!("Inferring for length 19");

            let split_off_point = 20 as usize;

            let mut vals_2 = vals.split_off(split_off_point);

            let mut ret = efficient_infer(vals)?;

            let mut ret_2 = efficient_infer(&mut vals_2)?;

            ret.append(&mut ret_2);

            return Ok(ret);
        }
        23 => {
            tracing::trace!("Inferring for length 23");

            let split_off_point = 20 as usize;

            let mut vals_2 = vals.split_off(split_off_point);

            let mut ret = efficient_infer(vals)?;

            let mut ret_2 = efficient_infer(&mut vals_2)?;

            ret.append(&mut ret_2);

            return Ok(ret);
        }
        25 => {
            tracing::trace!("Inferring for length 25");

            let split_off_point = 24 as usize;

            let mut vals_2 = vals.split_off(split_off_point);

            let mut ret = efficient_infer(vals)?;

            let mut ret_2 = efficient_infer(&mut vals_2)?;

            ret.append(&mut ret_2);

            return Ok(ret);
        }
        26 => {
            tracing::trace!("Inferring for length 26");

            let split_off_point = 24 as usize;

            let mut vals_2 = vals.split_off(split_off_point);

            let mut ret = efficient_infer(vals)?;

            let mut ret_2 = efficient_infer(&mut vals_2)?;

            ret.append(&mut ret_2);

            return Ok(ret);
        }
        29 => {
            tracing::trace!("Inferring for length 29");

            let split_off_point = 28 as usize;

            let mut vals_2 = vals.split_off(split_off_point);

            let mut ret = efficient_infer(vals)?;
            let mut ret_2 = efficient_infer(&mut vals_2)?;

            ret.append(&mut ret_2);

            return Ok(ret);
        }
        _ => {
            tracing::trace!("Inferring for length 29");

            let split_off_point = 30 as usize;

            let mut vals_2 = vals.split_off(split_off_point);

            let mut ret = efficient_infer(vals)?;

            let mut ret_2 = efficient_infer(&mut vals_2)?;

            ret.append(&mut ret_2);

            return Ok(ret);
        }
    }
}

pub async fn inference_loop(receiver: message_input_receiver) -> anyhow::Result<()> {
    let normalizer = videofftstats::fft_video_normalizer::new(
        /*path_file_bin64_mu: String =*/ "/data/input/train_mean.64bin",
        /*path_file_bin64_sigma: String =*/ "/data/input/train_sigma.64bin",
    )?;

    let normalizer: std::sync::Arc<videofftstats::fft_video_normalizer> =
        std::sync::Arc::from(normalizer);

    loop {
        let mut tensors = Vec::<videofft::fft_video>::new();
        let mut senders = Vec::<message_output_sender>::new();
        let mut do_loop = true;
        let mut do_infer = false;

        if true {
            let input_msg = receiver.recv().await;

            match input_msg {
                Ok(o) => {
                    tensors.extend_from_slice(o.tensor.as_slice());

                    for i in o.oneshot_send_channel.into_iter() {
                        senders.push(i);
                    }

                    do_loop = tensors.len() <= 20;
                    do_infer = true;
                }
                Err(e) => {
                    tracing::error!(
                        "Failed to send inference request to the serving thread due to {}",
                        e
                    );
                    do_loop = false;
                    do_infer = false;
                }
            }
        }

        while do_loop {
            let message_input = receiver
                .recv_timeout(std::time::Duration::from_millis(200))
                .await;

            match message_input {
                Ok(o) => {
                    tensors.extend_from_slice(o.tensor.as_slice());

                    for i in o.oneshot_send_channel.into_iter() {
                        senders.push(i);
                    }

                    do_loop = tensors.len() <= 20;
                    do_infer = true;
                }
                Err(e) => {
                    tracing::info!(
                        "Did not receive another batch before the timeout {}, proceeding to infer",
                        e
                    );
                    do_loop = false;
                }
            }
        }

        if do_infer {
            let tmp_norm = normalizer.clone();

            let ret = tokio::task::spawn_blocking(move || {
                tmp_norm.normalize_vec(&mut tensors);
                efficient_infer(/*vals: &mut Vec<videofft::fft_video> =*/ &mut tensors)
            })
            .await;

            match ret {
                Ok(o) => {
                    match o {
                        Ok(m) => {
                            for (i, j) in m.into_iter().zip(senders.into_iter()) {
                                j.send(i);
                            }
                        }
                        Err(e) => {
                            drop(senders);
                            tracing::error!("Inference failed due to {}", e);
                        }
                    };
                }
                Err(e) => {
                    drop(senders);
                    tracing::error!(
                        "The blocking thread to run RD inference failed due to {}",
                        e
                    );
                }
            };
        }
    }
}

pub struct client {
    sender: message_input_sender,
    handle: Option<tokio::task::JoinHandle<anyhow::Result<()>>>,
    file_store: filestore::file_store,
}

impl Drop for client {
    fn drop(&mut self) {
        match self.handle.take() {
            Some(o) => {
                o.abort();
            }
            None => {}
        }
    }
}

impl client {
    pub async fn new() -> anyhow::Result<std::sync::Arc<Self>> {
        let (sender, receiver) = get_message_input_pair();
        let tmp = inference_loop(receiver);
        let handle = tokio::task::spawn(tmp);

        return Ok(std::sync::Arc::new(Self {
            sender: sender,
            handle: Some(handle),
            file_store: filestore::file_store::new().await?,
        }));
    }

    pub async fn do_infer_on_fft_tensor(
        &self,
        tensors_input: Vec<videofft::fft_video>,
    ) -> anyhow::Result<Vec<inferencerelated::infer_results>> {
        let mut oneshot_receive_channel =
            Vec::<message_output_receiver>::with_capacity(tensors_input.len());

        let msg = {
            let mut oneshot_send_channel =
                Vec::<message_output_sender>::with_capacity(tensors_input.len());

            for _i in 0..tensors_input.len() {
                let (sender, receiver) = get_message_output_pair();
                oneshot_send_channel.push(sender);
                oneshot_receive_channel.push(receiver);
            }

            message_input {
                tensor: tensors_input,
                oneshot_send_channel: oneshot_send_channel,
            }
        };

        match self.sender.send(msg).await {
            Ok(_) => {
                tracing::info!("Sent inference request to the serving thread");
            }
            Err(e) => {
                tracing::error!(
                    "Failed to send inference request to the serving thread due to {}",
                    e
                );
                return Err(anyhow::format_err!(
                    "Failed to send inference request to the serving thread"
                ));
            }
        };

        let mut ret =
            Vec::<inferencerelated::infer_results>::with_capacity(oneshot_receive_channel.len());

        for i in oneshot_receive_channel.into_iter() {
            let tmp = i.recv_async().await;
            match tmp {
                Ok(o) => {
                    ret.push(o);
                }
                Err(e) => {
                    tracing::error!("inference failed on one of the video clips due to {}", e);
                    ret.push(inferencerelated::infer_results::default());
                }
            };
        }

        return Ok(ret);
    }

    pub async fn do_infer_on_video_file(
        &self,
        key: &hasher::blob_hash,
    ) -> anyhow::Result<Vec<inferencerelated::infer_results>> {
        let list_video_fft_tensor = {
            let slicer = {
                let mmap = self
                    .file_store
                    .get_raw_tensor(
                        &key, /*fps =*/ 8 as f32, /*size_x =*/ 1280,
                        /*size_y =*/ 720,
                    )
                    .await?;

                videoview::video_slicer_mapped::new(
                    mmap, /*fps =*/ 8 as f32, /*size_x =*/ 1280, /*size_y =*/ 720,
                    /*size_c =*/ 3,
                )
            }?;

            let video_tensor = slicer.get_video_tensor()?;

            let tmp = tokio::task::spawn_blocking(move || {
                videofft::fft_video::windowed_from_torch_video_tensor(
                    /*tensor_video_input: &tch::Tensor =*/ &video_tensor,
                    /*use_gpu: bool =*/ true,
                )
            })
            .await??;
            tmp
        };

        let tmp = self.do_infer_on_fft_tensor(list_video_fft_tensor).await;

        tmp
    }
}
