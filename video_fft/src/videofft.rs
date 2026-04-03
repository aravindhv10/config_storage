use crate::export;
use anyhow::Context;
use rayon::prelude::*;
use std::io::Write;
use tch::IndexOp;

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
    pub fn save(&self, filename: &str) -> anyhow::Result<()> {
        let file = std::fs::File::create(filename)?;
        let mut writer = std::io::BufWriter::new(file);
        let size = std::mem::size_of::<fft_video>();

        let bytes = unsafe { std::slice::from_raw_parts((self as *const Self) as *const u8, size) };

        writer.write_all(bytes)?;
        return Ok(());
    }

    fn from_torch_fft_tensor(
        tensor_fft_input: &tch::Tensor,
    ) -> anyhow::Result<std::sync::Arc<Self>> {
        if true {
            "################################";
            "# Do the check: ################";
            "################################";

            if tensor_fft_input.kind() != tch::Kind::Float {
                anyhow::bail!(
                    "Input tensor must be Kind::Float, found {:?}",
                    tensor_fft_input.kind()
                );
            } else {
                const expected_size: usize = 6 * 160 * 160 * 60;
                let actual_size: usize = tensor_fft_input.numel();
                if actual_size != expected_size {
                    anyhow::bail!(
                        "Tensor size mismatch: expected {} elements, found {}",
                        expected_size,
                        actual_size
                    );
                }
            }
        }

        let mut store: std::sync::Arc<std::mem::MaybeUninit<Self>> = std::sync::Arc::new_uninit();

        if true {
            "################################";
            "# Do the init: #################";
            "################################";
            let data: *mut Self =
                std::sync::Arc::<std::mem::MaybeUninit<Self>>::get_mut(&mut store)
                    .context("Failed to obtain unique mutable access to the newly allocated Arc")?
                    .as_mut_ptr();

            const size: [i64; 4] = [6, 160, 160, 60];
            const strides: [i64; 4] = [160 * 160 * 60, 160 * 60, 60, 1];

            if true {
                "################################";
                "# Now initialize the tensors: ##";
                "################################";

                let mut out_tensor: tch::Tensor = unsafe {
                    tch::Tensor::from_blob(
                        data as *mut u8,
                        &size,
                        &strides,
                        tch::Kind::Float,
                        tch::Device::Cpu,
                    )
                };

                if true {
                    "################################";
                    "# Do the copy: #################";
                    "################################";

                    out_tensor.copy_(&tensor_fft_input);
                }
            }
        }

        let final_video: std::sync::Arc<Self> = unsafe { store.assume_init() };

        return Ok(final_video);
    }

    pub fn from_torch_video_tensor(
        tensor_video_input: &tch::Tensor,
        use_gpu: bool,
    ) -> anyhow::Result<std::boxed::Box<Self>> {
        if true {
            "################################";
            "# Do the check: ################";
            "################################";

            if tensor_video_input.kind() != tch::Kind::Uint8 {
                anyhow::bail!(
                    "Input tensor must be Kind::Uint8, found {:?}",
                    tensor_video_input.kind()
                );
            } else {
                let expected_size: usize = (tensor_video_input.size()[0] * 720 * 1280 * 3) as usize;
                let actual_size: usize = tensor_video_input.numel();

                if actual_size != expected_size {
                    anyhow::bail!(
                        "Tensor size mismatch: expected {} elements, found {}",
                        expected_size,
                        actual_size
                    );
                }
            }
        }

        let mut store: std::boxed::Box<std::mem::MaybeUninit<Self>> = std::boxed::Box::new_uninit();

        if true {
            "################################";
            "# Perform the FFT ##############";
            "################################";

            let data: *mut Self = store.as_mut_ptr();

            unsafe {
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
                );
            }
        }

        let final_video: std::boxed::Box<Self> = unsafe { store.assume_init() };

        return Ok(final_video);
    }

    pub fn from_list_torch_video_tensor(
        list_torch_video_tensor: Vec<tch::Tensor>,
        use_gpu: bool,
    ) -> anyhow::Result<Vec<Self>> {
        if list_torch_video_tensor.len() > 0 {
            let pool = rayon::ThreadPoolBuilder::new().num_threads(4).build()?;

            let length = list_torch_video_tensor.len();

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

            let mut ret2 = Vec::<Self>::with_capacity(length);

            for i in ret.into_iter() {
                match i {
                    Ok(o) => {
                        ret2.push(*o);
                    }
                    Err(e) => {
                        eprintln!("Failed to FFT a vector due to {}", e);
                    }
                }
            }

            return Ok(ret2);
        } else {
            return Err(anyhow::format_err!("Input vector is empty"));
        }
    }

    fn from_windowed_torch_video_tensor(
        tensor_video_input: &tch::Tensor,
        use_gpu: bool,
    ) -> anyhow::Result<Vec<Self>> {
        let total_video_length = tensor_video_input.size()[0];
        if total_video_length < 120 {
            return Err(anyhow::format_err!("Video too short..."));
        } else if (120 <= total_video_length) && (total_video_length < 176) {
            return from_list_torch_video_tensor(
                /*list_torch_video_tensor: Vec<tch::Tensor> =*/ vec![tensor_video_input],
                /*use_gpu: bool =*/ use_gpu,
            );
        } else {
            let float_val = (((total_video_length - 160) as f64) / 40.0) as f64;

            let floor_val = float_val.floor();

            let diff = float_val - floor_val;

            let num_windows: usize = {
                if diff < 0.25 {
                    (floor_val as usize) + 1
                } else {
                    (floor_val as usize) + 2
                }
            };

            let mut list_torch_video_tensor = Vec::<tch::Tensor>::with_capacity(num_windows);

            for i in 1..=num_windows {
                let end = (((total_video_length - 160) * (i - 1)) / (num_windows - 1)) + 160;
                let start = end - 160;
                list_torch_video_tensor.push(tensor_video_input.i((start..end, .., .., ..)));
            }

            return Self::from_list_torch_video_tensor(
                /*list_torch_video_tensor: Vec<tch::Tensor> =*/ list_torch_video_tensor,
                /*use_gpu: bool =*/ use_gpu,
            );
        }
    }
}
