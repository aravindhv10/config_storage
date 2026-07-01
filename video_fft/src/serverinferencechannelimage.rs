use crate::inferencerelatedimage;

pub const GOOD_BATCH_SIZE: u8 = 16;

struct message_input {
    tensor: tch::Tensor,
    oneshot_send_channel: oneshot::Sender<Vec<inferencerelatedimage::infer_results>>,
}

struct inference_communicator {
    sender: flume::Sender<message_input>,
}

struct inference_slave {
    receiver: flume::Receiver<message_input>,
}

pub struct inference_pair {
    slave_sender: inference_communicator,
    handle: Option<std::thread::JoinHandle<anyhow::Result<()>>>,
}

impl inference_communicator {
    fn new(sender_in: flume::Sender<message_input>) -> Self {
        Self { sender: sender_in }
    }

    fn do_infer_on_image_batch_tensor(
        &self,
        mut tensors_input: tch::Tensor,
    ) -> anyhow::Result<Vec<inferencerelatedimage::infer_results>> {
        let (sender, receiver) = oneshot::channel::<Vec<inferencerelatedimage::infer_results>>();

        let msg = message_input {
            tensor: tensors_input,
            oneshot_send_channel: sender,
        };

        self.sender.send(msg);

        let ret = receiver.recv()?;

        return Ok(ret);
    }

    async fn do_infer_on_image_batch_tensor_async(
        &self,
        mut tensors_input: tch::Tensor,
    ) -> anyhow::Result<Vec<inferencerelatedimage::infer_results>> {
        let (sender, receiver) = oneshot::channel::<Vec<inferencerelatedimage::infer_results>>();

        let msg = message_input {
            tensor: tensors_input,
            oneshot_send_channel: sender,
        };

        self.sender.send(msg);

        let ret = receiver.await?;

        return Ok(ret);
    }
}

impl inference_slave {
    pub fn new() -> (Self, inference_communicator) {
        let (sender, receiver) = flume::unbounded::<message_input>();
        return (
            Self { receiver: receiver },
            inference_communicator::new(sender),
        );
    }

    fn efficient_infer(
        mut vals: Vec<tch::Tensor>,
        batch_size: u8,
    ) -> Vec<Result<Vec<inferencerelatedimage::infer_results>, String>> {
        let mut ret: Vec<Result<Vec<inferencerelatedimage::infer_results>, String>> = Vec::new();
        let mut infer_slave = inferencerelatedimage::infer_slave::new(batch_size);
        for i in vals.into_iter() {
            let tmp = infer_slave.infer(&i);
            match tmp {
                Ok(o) => {
                    ret.push(Ok(o));
                }
                Err(e) => {
                    ret.push(Err(format!("Inference failed {}", e)));
                }
            }
        }
        return ret;
    }

    pub fn inference_loop(&self) -> anyhow::Result<()> {
        loop {
            let mut tensors = Vec::<tch::Tensor>::new();
            let mut senders =
                Vec::<oneshot::Sender<Vec<inferencerelatedimage::infer_results>>>::new();
            let mut do_loop = true;
            let mut do_infer = false;

            if true {
                let input_msg = self.receiver.recv();

                match input_msg {
                    Ok(o) => {
                        tensors.push(o.tensor);
                        senders.push(o.oneshot_send_channel);
                        do_loop = tensors.len() <= 8;
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
                        tensors.push(o.tensor);
                        senders.push(o.oneshot_send_channel);
                        do_loop = tensors.len() <= 8;
                        do_infer = true;
                    }
                    Err(e) => {
                        do_loop = false;
                    }
                }
            }

            if do_infer {
                let res = Self::efficient_infer(tensors, GOOD_BATCH_SIZE);
                for (x, y) in res.into_iter().zip(senders.into_iter()) {
                    match x {
                        Ok(o) => {
                            tracing::info!("Inference succeeded, sending results");
                            y.send(o);
                        }
                        Err(e) => {
                            tracing::error!("Image inference for batch failed due to {}", e);
                            drop(y);
                        }
                    }
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
    pub fn new() -> Self {
        let (slave_inf, slave_sender) = inference_slave::new();
        let handle_inference = std::thread::spawn(move || slave_inf.inference_loop());

        Self {
            slave_sender: slave_sender,
            handle: Some(handle_inference),
        }
    }

    pub fn do_infer_on_image_tensor(
        &self,
        mut tensors_input: tch::Tensor,
    ) -> anyhow::Result<Vec<inferencerelatedimage::infer_results>> {
        self.slave_sender
            .do_infer_on_image_batch_tensor(tensors_input)
    }
}
