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

struct message_input {
    tensor: videofft::fft_video,
    oneshot_send_channel: oneshot::Sender<inferencerelated::infer_results>,
}

struct inference_slave {
    receiver: flume::Receiver<message_input>,
}

impl inference_slave {
    pub fn new() -> (Self, flume::Sender<message_input>) {
        let (sender, receiver) = flume::unbounded::<message_input>();
        return (Self { receiver: receiver }, sender);
    }

    pub fn inference_loop(&self) -> anyhow::Result<()> {
        loop {
            let mut tensors = Vec::<videofft::fft_video>::new();
            let mut senders = Vec::<oneshot::Sender<inferencerelated::infer_results>>::new();

            // Receive the 1st message
            if true {
                let message_input = self.receiver.recv()?;
                tensors.push(message_input.tensor);
                senders.push(message_input.oneshot_send_channel);
            }

            // Try to receive the subsequent messages
            let mut do_loop = true;
            while do_loop {
                let message_input = self
                    .receiver
                    .recv_timeout(std::time::Duration::from_millis(200));

                match message_input {
                    Ok(o) => {
                        tensors.push(o.tensor);
                        senders.push(o.oneshot_send_channel);
                    }
                    Err(e) => {
                        do_loop = false;
                    }
                }
            }

            eprintln!(
                "Got messages with length {} and {}",
                tensors.len(),
                senders.len()
            );
        }
    }
}

fn main() -> anyhow::Result<()> {
    if true {
        let (sender, receiver) = oneshot::channel::<inferencerelated::infer_results>();
        let (sender, receiver) = flume::unbounded::<message_input>();
    }

    let (inference_slave, request_sender) = inference_slave::new();

    Ok(())
}
