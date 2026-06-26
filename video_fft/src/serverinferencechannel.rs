use crate::filestore;
use crate::hasher;
use crate::inferencerelated;
use crate::videofft;
use crate::videofftstats;
use crate::videoview;
use tch::IndexOp;

struct message_input {
    tensor: Vec<videofft::fft_video>,
    oneshot_send_channel: Vec<oneshot::Sender<inferencerelated::infer_results>>,
}

struct inference_communicator {
    sender: flume::Sender<message_input>,
    normalizer: std::boxed::Box<videofftstats::fft_video_normalizer>,
    file_store: filestore::file_store,
}

struct inference_slave {
    receiver: flume::Receiver<message_input>,
}

pub struct inference_pair {
    slave_sender: inference_communicator,
    handle: Option<std::thread::JoinHandle<anyhow::Result<()>>>,
}

impl inference_communicator {
    async fn new(sender_in: flume::Sender<message_input>) -> anyhow::Result<Self> {
        let normalizer = videofftstats::fft_video_normalizer::new(
            /*path_file_bin64_mu: String =*/ "/data/input/train_mean.64bin",
            /*path_file_bin64_sigma: String =*/ "/data/input/train_sigma.64bin",
        )
        .unwrap();

        Ok(Self {
            sender: sender_in,
            normalizer: normalizer,
            file_store: filestore::file_store::new().await?,
        })
    }

    fn do_infer_on_fft_tensor(
        &self,
        mut tensors_input: Vec<videofft::fft_video>,
    ) -> anyhow::Result<Vec<inferencerelated::infer_results>> {
        self.normalizer.normalize_vec(&mut tensors_input);

        let mut oneshot_receive_channel =
            Vec::<oneshot::Receiver<inferencerelated::infer_results>>::with_capacity(
                tensors_input.len(),
            );

        let msg = {
            let mut oneshot_send_channel =
                Vec::<oneshot::Sender<inferencerelated::infer_results>>::with_capacity(
                    tensors_input.len(),
                );

            for i in 0..tensors_input.len() {
                let (sender, receiver) = oneshot::channel::<inferencerelated::infer_results>();
                oneshot_send_channel.push(sender);
                oneshot_receive_channel.push(receiver);
            }

            message_input {
                tensor: tensors_input,
                oneshot_send_channel: oneshot_send_channel,
            }
        };

        self.sender.send(msg);

        let mut ret =
            Vec::<inferencerelated::infer_results>::with_capacity(oneshot_receive_channel.len());

        for i in oneshot_receive_channel.into_iter() {
            ret.push(i.recv()?);
        }

        return Ok(ret);
    }

    async fn do_infer_on_fft_tensor_async(
        &self,
        mut tensors_input: Vec<videofft::fft_video>,
    ) -> anyhow::Result<Vec<inferencerelated::infer_results>> {
        self.normalizer.normalize_vec(
            /*x: &mut Vec<videofft::fft_video> =*/ &mut tensors_input,
        );

        let mut oneshot_receive_channel =
            Vec::<oneshot::Receiver<inferencerelated::infer_results>>::with_capacity(
                tensors_input.len(),
            );

        let msg = {
            let mut oneshot_send_channel =
                Vec::<oneshot::Sender<inferencerelated::infer_results>>::with_capacity(
                    tensors_input.len(),
                );

            for i in 0..tensors_input.len() {
                let (sender, receiver) = oneshot::channel::<inferencerelated::infer_results>();
                oneshot_send_channel.push(sender);
                oneshot_receive_channel.push(receiver);
            }

            message_input {
                tensor: tensors_input,
                oneshot_send_channel: oneshot_send_channel,
            }
        };

        self.sender.send(msg);

        let mut ret =
            Vec::<inferencerelated::infer_results>::with_capacity(oneshot_receive_channel.len());

        for i in oneshot_receive_channel.into_iter() {
            ret.push(i.await?);
        }

        return Ok(ret);
    }

    async fn do_infer_on_video_file(
        &self,
        key: &hasher::blob_hash,
    ) -> anyhow::Result<Vec<inferencerelated::infer_results>> {
        let mut list_video_fft_tensor = {
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

        let tmp = self
            .do_infer_on_fft_tensor_async(list_video_fft_tensor)
            .await;

        tmp
    }
}

impl inference_slave {
    pub async fn new() -> anyhow::Result<(Self, inference_communicator)> {
        let (sender, receiver) = flume::unbounded::<message_input>();
        Ok((
            Self { receiver: receiver },
            inference_communicator::new(sender).await?,
        ))
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

                let mut ret = Self::efficient_infer(vals)?;

                let mut ret_2 = Self::efficient_infer(&mut vals_2)?;

                ret.append(&mut ret_2);

                return Ok(ret);
            }
            7 => {
                tracing::trace!("Inferring for length 7");

                let split_off_point = 4 as usize;

                let mut vals_2 = vals.split_off(split_off_point);

                let mut ret = Self::efficient_infer(vals)?;

                let mut ret_2 = Self::efficient_infer(&mut vals_2)?;

                ret.append(&mut ret_2);

                return Ok(ret);
            }
            10 => {
                tracing::trace!("Inferring for length 10");

                let split_off_point = 8 as usize;

                let mut vals_2 = vals.split_off(split_off_point);

                let mut ret = Self::efficient_infer(vals)?;

                let mut ret_2 = Self::efficient_infer(&mut vals_2)?;

                ret.append(&mut ret_2);

                return Ok(ret);
            }
            11 => {
                tracing::trace!("Inferring for length 11");

                let split_off_point = 8 as usize;

                let mut vals_2 = vals.split_off(split_off_point);

                let mut ret = Self::efficient_infer(vals)?;

                let mut ret_2 = Self::efficient_infer(&mut vals_2)?;

                ret.append(&mut ret_2);

                return Ok(ret);
            }
            13 => {
                tracing::trace!("Inferring for length 13");

                let split_off_point = 12 as usize;

                let mut vals_2 = vals.split_off(split_off_point);

                let mut ret = Self::efficient_infer(vals)?;

                let mut ret_2 = Self::efficient_infer(&mut vals_2)?;

                ret.append(&mut ret_2);

                return Ok(ret);
            }
            14 => {
                tracing::trace!("Inferring for length 14");

                let split_off_point = 12 as usize;

                let mut vals_2 = vals.split_off(split_off_point);

                let mut ret = Self::efficient_infer(vals)?;

                let mut ret_2 = Self::efficient_infer(&mut vals_2)?;

                ret.append(&mut ret_2);

                return Ok(ret);
            }
            17 => {
                tracing::trace!("Inferring for length 17");

                let split_off_point = 16 as usize;

                let mut vals_2 = vals.split_off(split_off_point);

                let mut ret = Self::efficient_infer(vals)?;

                let mut ret_2 = Self::efficient_infer(&mut vals_2)?;

                ret.append(&mut ret_2);

                return Ok(ret);
            }
            19 => {
                tracing::trace!("Inferring for length 19");

                let split_off_point = 16 as usize;

                let mut vals_2 = vals.split_off(split_off_point);

                let mut ret = Self::efficient_infer(vals)?;

                let mut ret_2 = Self::efficient_infer(&mut vals_2)?;

                ret.append(&mut ret_2);

                return Ok(ret);
            }
            22 => {
                tracing::trace!("Inferring for length 19");

                let split_off_point = 20 as usize;

                let mut vals_2 = vals.split_off(split_off_point);

                let mut ret = Self::efficient_infer(vals)?;

                let mut ret_2 = Self::efficient_infer(&mut vals_2)?;

                ret.append(&mut ret_2);

                return Ok(ret);
            }
            23 => {
                tracing::trace!("Inferring for length 23");

                let split_off_point = 20 as usize;

                let mut vals_2 = vals.split_off(split_off_point);

                let mut ret = Self::efficient_infer(vals)?;

                let mut ret_2 = Self::efficient_infer(&mut vals_2)?;

                ret.append(&mut ret_2);

                return Ok(ret);
            }
            25 => {
                tracing::trace!("Inferring for length 25");

                let split_off_point = 24 as usize;

                let mut vals_2 = vals.split_off(split_off_point);

                let mut ret = Self::efficient_infer(vals)?;

                let mut ret_2 = Self::efficient_infer(&mut vals_2)?;

                ret.append(&mut ret_2);

                return Ok(ret);
            }
            26 => {
                tracing::trace!("Inferring for length 26");

                let split_off_point = 24 as usize;

                let mut vals_2 = vals.split_off(split_off_point);

                let mut ret = Self::efficient_infer(vals)?;

                let mut ret_2 = Self::efficient_infer(&mut vals_2)?;

                ret.append(&mut ret_2);

                return Ok(ret);
            }
            29 => {
                tracing::trace!("Inferring for length 29");

                let split_off_point = 28 as usize;

                let mut vals_2 = vals.split_off(split_off_point);

                let mut ret = Self::efficient_infer(vals)?;
                let mut ret_2 = Self::efficient_infer(&mut vals_2)?;

                ret.append(&mut ret_2);

                return Ok(ret);
            }
            _ => {
                tracing::trace!("Inferring for length 29");

                let split_off_point = 30 as usize;

                let mut vals_2 = vals.split_off(split_off_point);

                let mut ret = Self::efficient_infer(vals)?;

                let mut ret_2 = Self::efficient_infer(&mut vals_2)?;

                ret.append(&mut ret_2);

                return Ok(ret);
            }
        }
    }

    pub fn inference_loop(&self) -> anyhow::Result<()> {
        loop {
            let mut tensors = Vec::<videofft::fft_video>::new();
            let mut senders = Vec::<oneshot::Sender<inferencerelated::infer_results>>::new();
            let mut do_loop = true;
            let mut do_infer = false;

            if true {
                let input_msg = self.receiver.recv();

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
                        do_loop = false;
                        do_infer = false;
                    }
                }
            }

            while do_loop {
                let message_input = self
                    .receiver
                    .recv_timeout(std::time::Duration::from_millis(200));

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
                        do_loop = false;
                    }
                }
            }

            if do_infer {
                let ret = Self::efficient_infer(
                    /*vals: &mut Vec<videofft::fft_video> =*/ &mut tensors,
                )?;
                for (i, j) in ret.into_iter().zip(senders.into_iter()) {
                    j.send(i);
                }
            }
        }

        Ok(())
    }
}

impl Drop for inference_pair {
    fn drop(&mut self) {
        if let Some(handle) = self.handle.take() {
            let _ = handle.join();
        }
    }
}

impl inference_pair {
    pub async fn new() -> anyhow::Result<Self> {
        let (slave_inf, slave_sender) = inference_slave::new().await?;
        let handle_inference = std::thread::spawn(move || slave_inf.inference_loop());

        Ok(Self {
            slave_sender: slave_sender,
            handle: Some(handle_inference),
        })
    }

    pub fn do_infer_on_fft_tensor(
        &self,
        mut tensors_input: Vec<videofft::fft_video>,
    ) -> anyhow::Result<Vec<inferencerelated::infer_results>> {
        self.slave_sender.do_infer_on_fft_tensor(tensors_input)
    }

    pub async fn do_infer_on_video_file(
        &self,
        key: &hasher::blob_hash,
    ) -> anyhow::Result<Vec<inferencerelated::infer_results>> {
        self.slave_sender.do_infer_on_video_file(key).await
    }
}
