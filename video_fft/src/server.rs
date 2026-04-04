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
    oneshot_send_channel: oneshot::Receiver<inferencerelated::infer_results>,
}

struct inference_slave {
    receiver: flume::Receiver<message_input>,
}

fn main() -> anyhow::Result<()> {
    let (sender, receiver) = oneshot::channel::<inferencerelated::infer_results>();
    let (sender, receiver) = flume::unbounded::<message_input>();

    Ok(())
}
