use crate::inferencerelatedimagecvusability;

pub const GOOD_BATCH_SIZE: u8 = 8;

type message_output = Vec<f32>;
type message_output_sender = crossfire::oneshot::TxOneshot<message_output>;
type message_output_receiver = crossfire::oneshot::RxOneshot<message_output>;

fn get_message_output_pair() -> (message_output_sender, message_output_receiver) {
    crossfire::oneshot::oneshot::<message_output>()
}

struct message_input {
    tensor: tch::Tensor,
    oneshot_send_channel: message_output_sender,
}

type message_input_receiver = crossfire::AsyncRx<crossfire::mpsc::Array<message_input>>;
type message_input_sender = crossfire::MAsyncTx<crossfire::mpsc::Array<message_input>>;

fn get_message_input_pair() -> (message_input_sender, message_input_receiver) {
    crossfire::mpsc::bounded_async::<message_input>(32)
}

fn efficient_infer(vals: Vec<tch::Tensor>, batch_size: u8) -> Vec<Result<message_output, String>> {
    let mut ret: Vec<Result<message_output, String>> = Vec::new();
    let mut infer_slave = inferencerelatedimagecvusability::infer_slave::new(batch_size);
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

async fn inference_loop(receiver: message_input_receiver) -> anyhow::Result<()> {
    let max_delay = std::time::Duration::from_millis(200);
    loop {
        let mut tensors = Vec::<tch::Tensor>::new();
        let mut senders = Vec::<message_output_sender>::new();
        let mut do_loop = true;
        let mut do_infer = false;

        if true {
            let input_msg = receiver.recv().await;

            match input_msg {
                Ok(o) => {
                    tensors.push(o.tensor);
                    senders.push(o.oneshot_send_channel);
                    do_loop = tensors.len() <= 8;
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

        let start = tokio::time::Instant::now();
        while do_loop {
            let message_input = receiver
                .recv_timeout(std::time::Duration::from_millis(200))
                .await;

            match message_input {
                Ok(o) => {
                    tensors.push(o.tensor);
                    senders.push(o.oneshot_send_channel);
                    do_loop = tensors.len() <= 8;
                    do_infer = true;
                }
                Err(_e) => {
                    do_loop = start.elapsed() < max_delay;
                }
            }
        }

        if do_infer {
            let res =
                tokio::task::spawn_blocking(move || efficient_infer(tensors, GOOD_BATCH_SIZE))
                    .await?;

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
}

pub struct client {
    sender: message_input_sender,
    handle: Option<tokio::task::JoinHandle<anyhow::Result<()>>>,
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
    pub async fn new() -> std::sync::Arc<Self> {
        let (sender, receiver) = get_message_input_pair();
        let tmp = inference_loop(receiver);
        let handle = tokio::task::spawn(tmp);

        return std::sync::Arc::new(Self {
            sender: sender,
            handle: Some(handle),
        });
    }

    pub async fn do_infer_on_image_batch_tensor_async(
        &self,
        tensors_input: tch::Tensor,
    ) -> anyhow::Result<Vec<f32>> {
        let (sender, receiver) = get_message_output_pair();

        let msg = message_input {
            tensor: tensors_input,
            oneshot_send_channel: sender,
        };

        match self.sender.send(msg).await {
            Ok(_) => {
                tracing::info!("Successfullt sent request for inference");
            }
            Err(_) => {
                tracing::error!("Failed to send request for inference");
                return Err(anyhow::format_err!("Failed to send request for inference"));
            }
        };

        let ret = receiver.recv_async().await?;

        return Ok(ret);
    }
}
