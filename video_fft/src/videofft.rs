use crate::export;
use rayon::prelude::*;
use std::io::Write;
use tch::IndexOp;

use tokio::io::AsyncWriteExt;

#[inline(always)]
pub fn get_num_windows(total_video_length: u64) -> u8 {
    const IDEAL_LENGTH: u16 = 160 as u16;

    const MIN_LENGTH: u16 = (IDEAL_LENGTH * 3) >> 2;

    if total_video_length < (MIN_LENGTH as u64) {
        return 0 as u8;
    } else if total_video_length <= (IDEAL_LENGTH as u64) {
        return 1 as u8;
    } else {
        const STRIDE: u16 = IDEAL_LENGTH;

        let float_val =
            (((total_video_length - (IDEAL_LENGTH as u64)) as f64) / (STRIDE as f64)) as f64;

        let floor_val = float_val.floor();

        let diff = float_val - floor_val;

        let num_windows: u8 = {
            if diff < 0.25 {
                (floor_val as u8) + 1
            } else {
                (floor_val as u8) + 2
            }
        };

        return num_windows;
    }
}

#[repr(C)]
#[derive(Debug, Copy, Clone)]
pub struct a_t {
    pub t: [f32; 60],
}

#[repr(C)]
#[derive(Debug, Copy, Clone)]
pub struct a_x {
    pub x: [a_t; 160],
}

#[repr(C)]
#[derive(Debug, Copy, Clone)]
pub struct a_y {
    pub y: [a_x; 160],
}

#[repr(C)]
#[derive(Debug, Copy, Clone)]
pub struct a_p {
    pub p: [a_y; 6],
}

#[repr(C)]
#[derive(Debug, Copy, Clone)]
pub struct fft_video {
    pub v: a_p,
}

impl fft_video {
    pub async fn save(&self, filename: impl AsRef<std::path::Path>) -> anyhow::Result<()> {
        let file = tokio::fs::File::create(filename.as_ref()).await?;
        let mut writer = tokio::io::BufWriter::new(file);
        const size: usize = std::mem::size_of::<fft_video>();
        let bytes = unsafe { std::slice::from_raw_parts((self as *const Self) as *const u8, size) };
        writer.write_all(bytes).await?;
        return Ok(());
    }

    fn from_torch_fft_tensor(
        tensor_fft_input: &tch::Tensor,
    ) -> anyhow::Result<std::boxed::Box<Self>> {
        if tensor_fft_input.kind() != tch::Kind::Float {
            tracing::error!("datatype of tensor is not f32, returning");
            anyhow::bail!(
                "Input tensor must be Kind::Float, found {:?}",
                tensor_fft_input.kind()
            );
        }

        const EXPECTED_SIZE: usize = 6 * 160 * 160 * 60;
        let actual_size: usize = tensor_fft_input.numel();

        if actual_size != EXPECTED_SIZE {
            tracing::error!(
                "expected size of the tensor {} not matching with reality {} returning...",
                EXPECTED_SIZE,
                actual_size
            );
            anyhow::bail!(
                "Tensor size mismatch: expected {} elements, found {}",
                EXPECTED_SIZE,
                actual_size
            );
        }

        tracing::debug!("initializing memory");

        let mut store: std::boxed::Box<std::mem::MaybeUninit<Self>> = std::boxed::Box::new_uninit();

        if true {
            let data: *mut Self = store.as_mut_ptr();
            const SIZE: [i64; 4] = [6, 160, 160, 60];
            const STRIDES: [i64; 4] = [160 * 160 * 60, 160 * 60, 60, 1];

            tracing::debug!("Initialized memory, now passing to the tensor");

            let mut out_tensor: tch::Tensor = unsafe {
                tch::Tensor::from_blob(
                    data as *mut u8,
                    &SIZE,
                    &STRIDES,
                    tch::Kind::Float,
                    tch::Device::Cpu,
                )
            };
            tracing::debug!("Done with tensor interpretation. Performing the copy");

            out_tensor.copy_(&tensor_fft_input);

            tracing::debug!("Done with the copy");
        }

        // let final_video: std::sync::Arc<Self> = unsafe { store.assume_init() };
        let final_video = unsafe { store.assume_init() };

        return Ok(final_video);
    }

    pub fn from_torch_video_tensor(
        tensor_video_input: &tch::Tensor,
        use_gpu: bool,
    ) -> anyhow::Result<std::boxed::Box<Self>> {
        tracing::debug!("Came to from_torch_video_tensor");
        if tensor_video_input.kind() != tch::Kind::Uint8 {
            tracing::error!(
                "Input tensor must be Kind::Uint8, found {:?}",
                tensor_video_input.kind()
            );
            anyhow::bail!(
                "Input tensor must be Kind::Uint8, found {:?}",
                tensor_video_input.kind()
            );
        }

        let expected_size: usize = (tensor_video_input.size()[0] * 720 * 1280 * 3) as usize;
        let actual_size: usize = tensor_video_input.numel();

        if actual_size != expected_size {
            tracing::error!(
                "Tensor size mismatch: expected {} elements, found {}",
                expected_size,
                actual_size
            );
            anyhow::bail!(
                "Tensor size mismatch: expected {} elements, found {}",
                expected_size,
                actual_size
            );
        }

        tracing::debug!("Allocating the box pointer on the heap");
        let mut store: std::boxed::Box<std::mem::MaybeUninit<Self>> = std::boxed::Box::new_uninit();

        tracing::debug!("Passing the box pointer to torch tensor");
        if true {
            let data: *mut Self = store.as_mut_ptr();
            tracing::debug!("Got pointer from heap Box");

            let status: i32 = unsafe {
                export::do_fft_compress_efficient(
                    /*blob: *mut ::std::os::raw::c_void =*/
                    tensor_video_input.data_ptr(),
                    /*size_t: u16 =*/ tensor_video_input.size()[0] as u16,
                    /*size_y: u16 =*/ 720 as u16,
                    /*size_x: u16 =*/ 1280 as u16,
                    /*size_c: u8 =*/ 3,
                    /*fps: float32_t =*/ 8.0 as f32,
                    /*freq_limit: float32_t =*/ 3.0 as f32,
                    /*dest: *mut ::std::os::raw::c_void =*/
                    data as *mut ::std::os::raw::c_void,
                    /*bool use_gpu =*/ use_gpu,
                )
            } as i32;
            tracing::debug!("Called the fft function with status {}", status);

            if status != 0 {
                tracing::error!("FFT step failed with exit status {}...", status);
                return Err(anyhow::format_err!(
                    "FFT step failed with exit status {}...",
                    status
                ));
            }
        }

        tracing::debug!("Casting the final tensor");
        let final_video: std::boxed::Box<Self> = unsafe { store.assume_init() };

        tracing::debug!("Returning the fully valid tensor");
        return Ok(final_video);
    }

    pub fn from_list_torch_video_tensor(
        list_torch_video_tensor: Vec<tch::Tensor>,
        use_gpu: bool,
    ) -> anyhow::Result<Vec<Self>> {
        tracing::debug!("Started from_list_torch_video_tensor");

        if list_torch_video_tensor.len() == 0 {
            tracing::error!("Got empty vector to from_list_torch_video_tensor");
            return Err(anyhow::format_err!("Input vector is empty"));
        }

        let pool = rayon::ThreadPoolBuilder::new().num_threads(4).build()?;

        let length = list_torch_video_tensor.len();

        tracing::debug!("Length = {}", length);

        let ret: Vec<anyhow::Result<std::boxed::Box<Self>>> = pool.install(|| {
            list_torch_video_tensor
                .into_par_iter()
                .map(|i| {
                    Self::from_torch_video_tensor(
                        /*tensor_video_input: &tch::Tensor =*/ &i,
                        /*use_gpu: bool =*/ use_gpu,
                    )
                })
                .collect()
        });

        tracing::debug!("constructed the vec of boxed fft_video");

        let mut ret2 = Vec::<Self>::with_capacity(length);
        let mut ret2_ptr = ret2.as_mut_ptr();

        tracing::debug!("Initialized the needed capacity on heap with Vec");

        for i in ret.into_iter().filter_map(|i| i.ok()) {
            let tmp = &*i;
            unsafe { std::ptr::copy_nonoverlapping(tmp as *const Self, ret2_ptr, 1) };
            ret2_ptr = unsafe { ret2_ptr.add(1) };
            unsafe { ret2.set_len(ret2.len() + 1) };
        }

        tracing::debug!(
            "Done with the tight unsafe loops to copy data to sequential memory, returning the vec"
        );

        return Ok(ret2);
    }

    pub fn windowed_from_torch_video_tensor(
        tensor_video_input: &tch::Tensor,
        use_gpu: bool,
    ) -> anyhow::Result<Vec<Self>> {
        let total_video_length = tensor_video_input.size()[0];
        let num_windows: u8 =
            get_num_windows(/*total_video_length: u64 =*/ total_video_length as u64);
        tracing::info!("num_windows = {}", num_windows);

        match num_windows {
            0 => {
                tracing::error!("Video too short...");
                return Err(anyhow::format_err!("Video too short..."));
            }
            1 => {
                tracing::info!(
                    "window_length = 1, total_video_length = {}",
                    total_video_length
                );
                let tmp = Self::from_list_torch_video_tensor(
                    /*list_torch_video_tensor: Vec<tch::Tensor> =*/
                    vec![tensor_video_input.shallow_clone()],
                    /*use_gpu: bool =*/ use_gpu,
                );

                tracing::debug!("Constructed the Vec<fft_video>, returning it");

                tmp
            }
            _ => {
                let mut list_torch_video_tensor =
                    Vec::<tch::Tensor>::with_capacity(num_windows as usize);

                for i in 1..=num_windows {
                    let end = ((((total_video_length - 160) * ((i as i64) - 1))
                        / ((num_windows as i64) - 1))
                        + 160)
                        .min(total_video_length);

                    let start = (end - 160).max(0);

                    tracing::info!(
                        "i = {} , num_windows = {} , total_video_length = {}",
                        i,
                        num_windows,
                        total_video_length
                    );

                    tracing::info!("start = {} , end = {}", start, end);

                    list_torch_video_tensor.push(tensor_video_input.i((start..end, .., .., ..)));
                }

                let tmp = Self::from_list_torch_video_tensor(
                    /*list_torch_video_tensor: Vec<tch::Tensor> =*/ list_torch_video_tensor,
                    /*use_gpu: bool =*/ use_gpu,
                );

                tracing::debug!("Constructed the batch of fft_video. Returning it");

                tmp
            }
        }
    }
}
