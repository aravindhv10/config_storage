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
    tensor: Vec<videofft::fft_video>,
    oneshot_send_channel: Vec<oneshot::Sender<inferencerelated::infer_results>>,
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
        eprintln!("1");
        loop {
            let mut tensors = Vec::<videofft::fft_video>::new();
            let mut senders = Vec::<oneshot::Sender<inferencerelated::infer_results>>::new();

            eprintln!("2");

            if true {
                let input_msg = self.receiver.recv()?;
                tensors.extend_from_slice(input_msg.tensor.as_slice());
                for i in input_msg.oneshot_send_channel.into_iter() {
                    senders.push(i);
                }
            }

            // Receive the 1st message
            eprintln!("3");

            // Try to receive the subsequent messages
            let mut do_loop = true;

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

            if true {
                let mut infer_slave = inferencerelated::infer_slave::new(1);

                let ret = infer_slave
                    .infer(/*vals: &mut Vec<videofft::fft_video> =*/ &mut tensors)?;

                for (i, j) in ret.into_iter().zip(senders.into_iter()) {
                    j.send(i);
                }
            }
        }
        Ok(())
    }
}

fn main() -> anyhow::Result<()> {
    if false {
        let (sender, receiver) = oneshot::channel::<inferencerelated::infer_results>();
        let (sender, receiver) = flume::unbounded::<message_input>();
    }

    let args: Vec<String> = std::env::args().collect();

    if args.len() < 2 {
        return Err(anyhow::format_err!("Need atleast 1 file name to work"));
    } else {
        let (slave_inf, slave_sender) = inference_slave::new();

        let handle_inference = std::thread::spawn(move || slave_inf.inference_loop());

        let mut list_video_fft_tensor = {
            let slicer = videoview::video_slicer::new(
                /*path_file_video_input: String =*/ args[1].clone(),
                /*mut path_file_rawvideo_output: Option<String> =*/ None,
                /*fps: f32 =*/ 8.0,
                /*size_x: u16 =*/ 1280,
                /*size_y: u16 =*/ 720,
                /*size_c: u8 =*/ 3,
            )?;

            let video_tensor = slicer.get_video_tensor()?;

            videofft::fft_video::windowed_from_torch_video_tensor(
                /*tensor_video_input: &tch::Tensor =*/ &video_tensor,
                /*use_gpu: bool =*/ true,
            )?
        };

        /* Normalize the video tensor */
        {
            let normalizer = videofftstats::fft_video_normalizer::new(
                /*path_file_bin64_mu: String =*/ "/data/input/train_mean.64bin",
                /*path_file_bin64_sigma: String =*/ "/data/input/train_sigma.64bin",
            )?;

            normalizer.normalize_vec(
                /*x: &mut Vec<videofft::fft_video> =*/ &mut list_video_fft_tensor,
            );
        }

        let mut oneshot_send_channel =
            Vec::<oneshot::Sender<inferencerelated::infer_results>>::with_capacity(
                list_video_fft_tensor.len(),
            );

        let mut oneshot_receive_channel =
            Vec::<oneshot::Receiver<inferencerelated::infer_results>>::with_capacity(
                list_video_fft_tensor.len(),
            );

        for i in 0..list_video_fft_tensor.len() {
            let (sender, receiver) = oneshot::channel::<inferencerelated::infer_results>();
            oneshot_send_channel.push(sender);
            oneshot_receive_channel.push(receiver);
        }

        let msg = message_input {
            tensor: list_video_fft_tensor,
            oneshot_send_channel: oneshot_send_channel,
        };

        slave_sender.send(msg);

        for i in oneshot_receive_channel.into_iter() {
            let res = i.recv()?;
            eprintln!(
                "Received reply... {} {} {}",
                res.p_calm, res.p_contraversial, res.p_rd
            );
        }

        handle_inference.join();

        return Ok(());
    }
}
