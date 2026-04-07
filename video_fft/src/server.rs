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

pub mod infer {
    tonic::include_proto!("myrdvideoinferinfer");

    pub(crate) const FILE_DESCRIPTOR_SET: &[u8] = tonic::include_file_descriptor_set!("infer");
}

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
        match vals.len() {
            0 => {
                return Err(anyhow::format_err!("Input vector is empty..."));
            }
            1 => {
                eprintln!("Inferring for length 1");
                let mut infer_slave = inferencerelated::infer_slave::new(1);
                let ret = infer_slave.infer(/*vals: &mut Vec<videofft::fft_video> =*/ vals)?;
                return Ok(ret);
            }
            2 => {
                eprintln!("Inferring for length 2");
                let mut infer_slave = inferencerelated::infer_slave::new(2);
                let ret = infer_slave.infer(/*vals: &mut Vec<videofft::fft_video> =*/ vals)?;
                return Ok(ret);
            }
            3 | 6 | 9 | 15 | 18 | 21 | 27 | 30 => {
                eprintln!("Inferring for length 3");
                let mut infer_slave = inferencerelated::infer_slave::new(3);
                let ret = infer_slave.infer(/*vals: &mut Vec<videofft::fft_video> =*/ vals)?;
                return Ok(ret);
            }
            4 | 8 | 12 | 16 | 20 | 24 | 28 | 32 | 36 | 40 => {
                eprintln!("Inferring for length 4");
                let mut infer_slave = inferencerelated::infer_slave::new(4);
                let ret = infer_slave.infer(/*vals: &mut Vec<videofft::fft_video> =*/ vals)?;
                return Ok(ret);
            }
            5 => {
                eprintln!("Inferring for length 5");

                let split_off_point = 4 as usize;

                let mut vals_2 = vals.split_off(split_off_point);

                let mut ret = Self::efficient_infer(vals)?;

                let mut ret_2 = Self::efficient_infer(&mut vals_2)?;

                ret.append(&mut ret_2);

                return Ok(ret);
            }
            7 => {
                eprintln!("Inferring for length 7");

                let split_off_point = 4 as usize;

                let mut vals_2 = vals.split_off(split_off_point);

                let mut ret = Self::efficient_infer(vals)?;

                let mut ret_2 = Self::efficient_infer(&mut vals_2)?;

                ret.append(&mut ret_2);

                return Ok(ret);
            }
            10 => {
                eprintln!("Inferring for length 10");

                let split_off_point = 8 as usize;

                let mut vals_2 = vals.split_off(split_off_point);

                let mut ret = Self::efficient_infer(vals)?;

                let mut ret_2 = Self::efficient_infer(&mut vals_2)?;

                ret.append(&mut ret_2);

                return Ok(ret);
            }
            11 => {
                eprintln!("Inferring for length 11");

                let split_off_point = 8 as usize;

                let mut vals_2 = vals.split_off(split_off_point);

                let mut ret = Self::efficient_infer(vals)?;

                let mut ret_2 = Self::efficient_infer(&mut vals_2)?;

                ret.append(&mut ret_2);

                return Ok(ret);
            }
            13 => {
                eprintln!("Inferring for length 13");

                let split_off_point = 12 as usize;

                let mut vals_2 = vals.split_off(split_off_point);

                let mut ret = Self::efficient_infer(vals)?;

                let mut ret_2 = Self::efficient_infer(&mut vals_2)?;

                ret.append(&mut ret_2);

                return Ok(ret);
            }
            14 => {
                eprintln!("Inferring for length 14");

                let split_off_point = 12 as usize;

                let mut vals_2 = vals.split_off(split_off_point);

                let mut ret = Self::efficient_infer(vals)?;

                let mut ret_2 = Self::efficient_infer(&mut vals_2)?;

                ret.append(&mut ret_2);

                return Ok(ret);
            }
            17 => {
                eprintln!("Inferring for length 17");

                let split_off_point = 16 as usize;

                let mut vals_2 = vals.split_off(split_off_point);

                let mut ret = Self::efficient_infer(vals)?;

                let mut ret_2 = Self::efficient_infer(&mut vals_2)?;

                ret.append(&mut ret_2);

                return Ok(ret);
            }
            19 => {
                eprintln!("Inferring for length 19");

                let split_off_point = 16 as usize;

                let mut vals_2 = vals.split_off(split_off_point);

                let mut ret = Self::efficient_infer(vals)?;

                let mut ret_2 = Self::efficient_infer(&mut vals_2)?;

                ret.append(&mut ret_2);

                return Ok(ret);
            }
            22 => {
                eprintln!("Inferring for length 19");

                let split_off_point = 20 as usize;

                let mut vals_2 = vals.split_off(split_off_point);

                let mut ret = Self::efficient_infer(vals)?;

                let mut ret_2 = Self::efficient_infer(&mut vals_2)?;

                ret.append(&mut ret_2);

                return Ok(ret);
            }
            23 => {
                eprintln!("Inferring for length 23");

                let split_off_point = 20 as usize;

                let mut vals_2 = vals.split_off(split_off_point);

                let mut ret = Self::efficient_infer(vals)?;

                let mut ret_2 = Self::efficient_infer(&mut vals_2)?;

                ret.append(&mut ret_2);

                return Ok(ret);
            }
            25 => {
                eprintln!("Inferring for length 25");

                let split_off_point = 24 as usize;

                let mut vals_2 = vals.split_off(split_off_point);

                let mut ret = Self::efficient_infer(vals)?;

                let mut ret_2 = Self::efficient_infer(&mut vals_2)?;

                ret.append(&mut ret_2);

                return Ok(ret);
            }
            26 => {
                eprintln!("Inferring for length 26");

                let split_off_point = 24 as usize;

                let mut vals_2 = vals.split_off(split_off_point);

                let mut ret = Self::efficient_infer(vals)?;

                let mut ret_2 = Self::efficient_infer(&mut vals_2)?;

                ret.append(&mut ret_2);

                return Ok(ret);
            }
            29 => {
                eprintln!("Inferring for length 29");

                let split_off_point = 28 as usize;

                let mut vals_2 = vals.split_off(split_off_point);

                let mut ret = Self::efficient_infer(vals)?;
                let mut ret_2 = Self::efficient_infer(&mut vals_2)?;

                ret.append(&mut ret_2);

                return Ok(ret);
            }
            _ => {
                eprintln!("Inferring for length 29");

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

            if true {
                let input_msg = self.receiver.recv()?;
                tensors.extend_from_slice(input_msg.tensor.as_slice());
                for i in input_msg.oneshot_send_channel.into_iter() {
                    senders.push(i);
                }
            }

            // Try to receive the subsequent messages
            let mut do_loop = tensors.len() <= 30;

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

                        do_loop = tensors.len() <= 30;
                    }
                    Err(e) => {
                        do_loop = false;
                    }
                }
            }

            if true {
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

struct grpc_inferer {
    infpair: std::sync::Arc<inference_pair>,
}

impl grpc_inferer {
    fn new() -> Self {
        Self {
            infpair: std::sync::Arc::<inference_pair>::new(inference_pair::new()),
        }
    }
}

#[tonic::async_trait]
impl infer::rdvideoinfer_server::Rdvideoinfer for grpc_inferer {
    async fn doinfer(
        &self,
        request: tonic::Request<infer::Grpcvideodata>,
    ) -> std::result::Result<tonic::Response<infer::Grpcvideopredictionreply>, tonic::Status> {
        let video_data = &(request.into_inner().data);
        let hash = gxhash::gxhash64(&video_data, /* seed = */ 12345);
        let path_file_video_output = format!("/dev/shm/{:x}.mp4", hash);
        tokio::fs::write(path_file_video_output.as_str(), video_data).await?;
        let res = self.infpair.do_infer_on_video_file(&path_file_video_output);
        tokio::fs::remove_file(path_file_video_output.as_str()).await?;
        match res {
            Ok(o) => {
                let preds: Vec<infer::Grpcvideoprediction> = o
                    .iter()
                    .map(|i| infer::Grpcvideoprediction {
                        pa: i.p_calm,
                        pb: i.p_contraversial,
                        pc: i.p_rd,
                    })
                    .collect();
                return Ok(tonic::Response::new(infer::Grpcvideopredictionreply {
                    preds: preds,
                }));
            }
            Err(e) => {
                return Err(tonic::Status::internal("Internal error, inference failed"));
            }
        }

        Err(tonic::Status::ok("Done inference"))
    }
}

fn main() -> anyhow::Result<()> {
    let ip_v4 = std::net::IpAddr::V4(std::net::Ipv4Addr::new(0, 0, 0, 0));
    let port: u16 = 8001;
    let addr = std::net::SocketAddr::new(ip_v4, port);

    let rt = tokio::runtime::Builder::new_multi_thread()
        .thread_stack_size(1 << 28)
        .enable_all()
        .build()
        .unwrap();

    let service = tonic_reflection::server::Builder::configure()
        .register_encoded_file_descriptor_set(infer::FILE_DESCRIPTOR_SET)
        .build_v1()
        .unwrap();

    rt.block_on(async {
        tonic::transport::Server::builder()
            .add_service(service)
            .add_service(
                infer::rdvideoinfer_server::RdvideoinferServer::new(grpc_inferer::new())
                    .max_encoding_message_size(1 << 25)
                    .max_decoding_message_size(1 << 25),
            )
            .serve(addr)
            .await;
    });

    Ok(())
}
