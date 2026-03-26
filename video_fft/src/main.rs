use mimalloc::MiMalloc;

#[global_allocator]
static GLOBAL: MiMalloc = MiMalloc;

mod export;
mod videofn;
mod videoview;

use anyhow::Context;
use bytemuck::Contiguous;
use bytemuck::Pod;
use bytemuck::Zeroable;
use futures::stream;
use futures::stream::StreamExt;
use rayon::prelude::*;
use std::io::Write;
use tch::IndexOp;

const USE_GPU: bool = true;

// include!("export.rs");

#[repr(C)]
#[derive(Debug, Copy, Clone)]
struct a_t {
    t: [f32; 60],
}

#[repr(C)]
#[derive(Debug, Copy, Clone)]
struct a_x {
    x: [a_t; 160],
}

unsafe impl Zeroable for a_x {}
unsafe impl Pod for a_x {}

#[repr(C)]
#[derive(Debug, Copy, Clone)]
struct a_y {
    y: [a_x; 160],
}

unsafe impl Zeroable for a_y {}
unsafe impl Pod for a_y {}

#[repr(C)]
#[derive(Debug, Copy, Clone)]
struct a_p {
    p: [a_y; 6],
}

unsafe impl Zeroable for a_p {}
unsafe impl Pod for a_p {}

#[repr(C)]
#[derive(Debug, Copy, Clone)]
struct fft_video {
    v: a_p,
}

unsafe impl Zeroable for fft_video {}
unsafe impl Pod for fft_video {}

impl fft_video {
    fn save(&self, filename: &str) -> anyhow::Result<()> {
        let file = std::fs::File::create(filename)?;
        let mut writer = std::io::BufWriter::new(file);
        let size = std::mem::size_of::<fft_video>();
        let bytes =
            unsafe { std::slice::from_raw_parts((self as *const fft_video) as *const u8, size) };
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

    fn from_torch_video_tensor(
        tensor_video_input: &tch::Tensor,
        use_gpu: bool,
    ) -> anyhow::Result<std::sync::Arc<Self>> {
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

        let mut store: std::sync::Arc<std::mem::MaybeUninit<Self>> = std::sync::Arc::new_uninit();

        let data: *mut Self = std::sync::Arc::<std::mem::MaybeUninit<Self>>::get_mut(&mut store)
            .context("Failed to obtain unique mutable access to the newly allocated Arc")?
            .as_mut_ptr();

        if true {
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
        } else {
            unsafe {
                export::do_fft_compress(
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

        let final_video: std::sync::Arc<Self> = unsafe { store.assume_init() };

        return Ok(final_video);
    }
}

fn video_tensor_2_fft_file_160(
    tensor_video_input: tch::Tensor,
    path_dir_output: &str,
) -> anyhow::Result<String> {
    let total_video_length = tensor_video_input.size()[0];

    if total_video_length < 120 {
        return Err(anyhow::format_err!("Video too short..."));
    } else {
        std::fs::create_dir_all(path_dir_output)?;

        let use_gpu: bool = USE_GPU && tch::Cuda::is_available();

        if (120 <= total_video_length) && (total_video_length < 176) {
            let path_file_video_bin_output: String = path_dir_output.to_string() + "/out-1.bin";

            if !std::fs::exists(path_file_video_bin_output.as_str())? {
                fft_video::from_torch_video_tensor(
                    /*tensor_video_input: &tch::Tensor =*/
                    &tensor_video_input.i((0..total_video_length, .., .., ..)),
                    use_gpu,
                )?
                .save(path_file_video_bin_output.as_str())?;
            }

            return Ok("Successfully encoded the the whole video into a single file".to_string());
        } else {
            let float_val = (((total_video_length - 160) as f32) / 40.0) as f32;

            let diff = float_val - float_val.floor();

            let num_windows: i64 = {
                if diff < 0.25 {
                    (float_val.floor() as i64) + 1
                } else {
                    (float_val.ceil() as i64) + 1
                }
            };

            for i in 1..=num_windows {
                let path_file_video_bin_output: String =
                    path_dir_output.to_string() + "/out-" + i.to_string().as_str() + ".bin";

                if !std::fs::exists(path_file_video_bin_output.as_str())? {
                    let end = (((total_video_length - 160) * (i - 1)) / (num_windows - 1)) + 160;
                    let start = end - 160;

                    fft_video::from_torch_video_tensor(
                        /*tensor_video_input: &tch::Tensor =*/
                        &tensor_video_input.i((start..end, .., .., ..)),
                        use_gpu,
                    )?
                    .save(path_file_video_bin_output.as_str())?;
                }
            }

            return Ok("Successfully encoded the video into many pieces".to_string());
        }
    }
}

fn process_video_file(path_file_video_input: String) -> anyhow::Result<String> {
    let res = videoview::video_slicer::new(path_file_video_input.clone(), None, 8.0, 1280, 720, 3)?;
    let full_tensor = res.get_video_tensor()?;

    let path_dir_output = path_file_video_input + ".dir";

    return video_tensor_2_fft_file_160(
        /*tensor_video_input: tch::Tensor =*/ full_tensor,
        /*path_dir_output: &str =*/ path_dir_output.as_str(),
    );
}

#[repr(C)]
#[derive(Debug, Copy, Clone)]
struct a_t_64 {
    t: [f64; 60],
}

impl Default for a_t_64 {
    fn default() -> Self {
        Self {
            t: [0.0 as f64; 60],
        }
    }
}

impl a_t_64 {
    fn add_2_self(&mut self, other: &a_t) {
        for i in 0..self.t.len() {
            self.t[i] += other.t[i] as f64;
        }
    }

    fn add_2_self_64(&mut self, other: &Self) {
        for i in 0..self.t.len() {
            self.t[i] += other.t[i] as f64;
        }
    }
}

#[repr(C)]
#[derive(Debug, Copy, Clone)]
struct a_x_64 {
    x: [a_t_64; 160],
}

impl Default for a_x_64 {
    fn default() -> Self {
        Self {
            x: [a_t_64::default(); 160],
        }
    }
}

impl a_x_64 {
    fn add_2_self(&mut self, other: &a_x) {
        for i in 0..self.x.len() {
            self.x[i].add_2_self(&(other.x[i]));
        }
    }

    fn add_2_self_64(&mut self, other: &Self) {
        for i in 0..self.x.len() {
            self.x[i].add_2_self_64(&(other.x[i]));
        }
    }
}

#[repr(C)]
#[derive(Debug, Copy, Clone)]
struct a_y_64 {
    y: [a_x_64; 160],
}

impl Default for a_y_64 {
    fn default() -> Self {
        Self {
            y: [a_x_64::default(); 160],
        }
    }
}

impl a_y_64 {
    fn add_2_self(&mut self, other: &a_y) {
        for i in 0..self.y.len() {
            self.y[i].add_2_self(&(other.y[i]));
        }
    }

    fn add_2_self_64(&mut self, other: &Self) {
        for i in 0..self.y.len() {
            self.y[i].add_2_self_64(&(other.y[i]));
        }
    }
}

#[repr(C)]
#[derive(Debug, Copy, Clone)]
struct a_p_64 {
    p: [a_y_64; 6],
}

impl Default for a_p_64 {
    fn default() -> Self {
        Self {
            p: [a_y_64::default(); 6],
        }
    }
}

impl a_p_64 {
    fn add_2_self(&mut self, other: &a_p) {
        for i in 0..self.p.len() {
            self.p[i].add_2_self(&(other.p[i]));
        }
    }

    fn add_2_self_64(&mut self, other: &Self) {
        for i in 0..self.p.len() {
            self.p[i].add_2_self_64(&(other.p[i]));
        }
    }
}

#[repr(C)]
#[derive(Debug, Default, Clone)]
struct fft_video_64 {
    v: a_p_64,
}

impl fft_video_64 {
    fn add_2_self(&mut self, other: &fft_video) {
        self.v.add_2_self(&(other.v));
    }

    fn add_2_self_64(&mut self, other: &Self) {
        self.v.add_2_self_64(&(other.v));
    }
}

fn fft_all_video_files_under_dir(target_dir: &str) -> anyhow::Result<()> {
    let mut list_path_file_video: Vec<String> = vec![];

    for entry in jwalk::WalkDir::new(target_dir)
        .into_iter()
        .filter_map(|e| e.ok())
    {
        let path = entry.path();

        if !path.is_dir() {
            if let Some(ext) = path.extension() {
                if ext == "mp4" {
                    list_path_file_video.push(path.display().to_string());
                }
            }
        }
    }

    let pool = rayon::ThreadPoolBuilder::new()
        .num_threads(8)
        .build()
        .unwrap();

    let processed: Vec<anyhow::Result<String>> = pool.install(|| {
        list_path_file_video
            .into_par_iter() // Convert to a parallel iterator
            .map(process_video_file) // The function to map   |s| s.to_uppercase()
            .collect() // Gather back into a Vec
    });

    return Ok(());
}

async fn eval_actual_sum(
    list_path_file_video_input: &[String],
) -> anyhow::Result<std::boxed::Box<fft_video_64>> {
    let mut accumulator: std::boxed::Box<fft_video_64> =
        std::boxed::Box::new(fft_video_64::default());

    for i in list_path_file_video_input {
        let data = tokio::fs::read(i.as_str()).await?;
        let data_fft: &fft_video = unsafe { &*(data.as_ptr() as *const fft_video) };
        accumulator.add_2_self(data_fft);
    }

    Ok(accumulator)
}

async fn eval_sum(target_dir: &str) -> anyhow::Result<()> {
    let mut list_path_file_video: Vec<String> = vec![];

    for entry in jwalk::WalkDir::new(target_dir)
        .into_iter()
        .filter_map(|e| e.ok())
    {
        let path = entry.path();

        if !path.is_dir() {
            if let Some(ext) = path.extension() {
                if ext == "bin" {
                    list_path_file_video.push(path.display().to_string());
                }
            }
        }
    }

    const nthreads: usize = 16;
    const nchunks: usize = 1 << 12;

    let mut streams = vec![];
    for i in list_path_file_video.chunks(nchunks) {
        streams.push(eval_actual_sum(i));
    }

    let mut accumulator: std::boxed::Box<fft_video_64> =
        std::boxed::Box::new(fft_video_64::default());

    let mut jobs = stream::iter(streams).buffer_unordered(nthreads);

    while let Some(result) = jobs.next().await {
        let arr = result?;
        accumulator.add_2_self_64(&*arr);
    }

    println!("{:?}", accumulator);

    // eval_actual_sum(
    //     /*list_path_file_video_input: Vec<String> =*/ list_path_file_video,
    // )
    // .await?;

    Ok(())
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let args: Vec<String> = std::env::args().collect();

    if args.len() < 2 {
        eprintln!("Usage: {} <directory>", args[0]);
        std::process::exit(1);
    }

    let target_dir = args[1].to_string();

    eval_sum(target_dir.as_str()).await?;

    // tokio::task::spawn_blocking(move || fft_all_video_files_under_dir(/*target_dir: &str =*/ target_dir)).await?;

    Ok(())
}
