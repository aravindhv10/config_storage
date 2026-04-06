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

struct inference_communicator {
    sender: flume::Sender<message_input>,
    normalizer: std::boxed::Box<videofftstats::fft_video_normalizer>,
}

impl inference_communicator {
    fn new(sender_in: flume::Sender<message_input>) -> Self {
        let normalizer = videofftstats::fft_video_normalizer::new(
            /*path_file_bin64_mu: String =*/ "/data/input/train_mean.64bin",
            /*path_file_bin64_sigma: String =*/ "/data/input/train_sigma.64bin",
        )
        .unwrap();

        Self {
            sender: sender_in,
            normalizer: normalizer,
        }
    }

    fn do_infer_on_fft_tensor(
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
            ret.push(i.recv()?);
        }

        return Ok(ret);
    }

    fn do_infer_on_video_file(
        &self,
        path_file_video_input: &str,
    ) -> anyhow::Result<Vec<inferencerelated::infer_results>> {
        let mut list_video_fft_tensor = {
            let slicer = videoview::video_slicer::new(
                /*path_file_video_input: String =*/ path_file_video_input.to_string(),
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

        self.do_infer_on_fft_tensor(list_video_fft_tensor)
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
}

struct inference_slave {
    receiver: flume::Receiver<message_input>,
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
        vals: &mut Vec<videofft::fft_video>,
    ) -> anyhow::Result<Vec<inferencerelated::infer_results>> {
        let mut infer_slave = inferencerelated::infer_slave::new(1);
        let ret = infer_slave.infer(/*vals: &mut Vec<videofft::fft_video> =*/ vals)?;
        return Ok(ret);
    }

    pub fn inference_loop(&self) -> anyhow::Result<()> {
        loop {
            let mut tensors = Vec::<videofft::fft_video>::new();
            let mut senders = Vec::<oneshot::Sender<inferencerelated::infer_results>>::new();

            if true {
                let input_msg = self.receiver.recv()?;
                tensors.extend_from_slice(input_msg.tensor.as_slice());
                for i in input_msg.oneshot_send_channel.into_iter() {
                    senders.push(i);
                }
            }

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

            if true {
                let ret = Self::efficient_infer(
                    /*vals: &mut Vec<videofft::fft_video> =*/ &mut tensors,
                );
                for (i, j) in ret.into_iter().zip(senders.into_iter()) {
                    j.send(i);
                }
            }
        }

        Ok(())
    }
}

struct inference_pair {
    slave_sender: inference_communicator,
    handle: Option<std::thread::JoinHandle<anyhow::Result<()>>>,
}

impl Drop for inference_pair {
    fn drop(&mut self) {
        if let Some(handle) = self.handle.take() {
            let _ = handle.join();
        }
    }
}

impl inference_pair {
    fn new() -> Self {
        let (slave_inf, slave_sender) = inference_slave::new();
        let handle_inference = std::thread::spawn(move || slave_inf.inference_loop());

        Self {
            slave_sender: slave_sender,
            handle: Some(handle_inference),
        }
    }

    fn do_infer_on_fft_tensor(
        &self,
        mut tensors_input: Vec<videofft::fft_video>,
    ) -> anyhow::Result<Vec<inferencerelated::infer_results>> {
        self.slave_sender.do_infer_on_fft_tensor(tensors_input)
    }

    fn do_infer_on_video_file(
        &self,
        path_file_video_input: &str,
    ) -> anyhow::Result<Vec<inferencerelated::infer_results>> {
        self.slave_sender
            .do_infer_on_video_file(/*path_file_video_input: &str =*/ path_file_video_input)
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
        let tmpslave = inference_pair::new();
        let res = tmpslave
            .do_infer_on_video_file(/*path_file_video_input: &str =*/ args[1].as_str())?;

        res.into_iter().for_each(|i| {
            eprintln!(
                "inference results: {} {} {}\n",
                i.p_calm, i.p_contraversial, i.p_rd
            )
        });

        return Ok(());
    }
}
