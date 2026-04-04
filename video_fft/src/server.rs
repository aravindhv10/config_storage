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
        return (Self { receiver: receive }, sender);
    }

    pub fn inference_loop(&self) -> anyhow::Result<()> {
        loop {
            let message_input = self.receiver.recv()?;
            let mut tensors = Vec::<videofft::fft_video>::new();
            let mut senders = Vec::<oneshot::Sender<inferencerelated::infer_results>>::new();
            tensors.push(message_input.tensor);
            senders.push(message_input.oneshot_send_channel);

            loop {
                let message_input = self
                    .receiver
                    .recv_timeout(std::time::Duration::from_millis(200));
            }
        }
    }
}

fn main() -> anyhow::Result<()> {
    let (sender, receiver) = oneshot::channel::<inferencerelated::infer_results>();
    let (sender, receiver) = flume::unbounded::<message_input>();

    Ok(())
}
