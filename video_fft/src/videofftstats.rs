use crate::videofft;
use futures::stream;
use futures::stream::StreamExt;
use std::io::Read;
use tokio::io::AsyncWriteExt;

#[repr(C)]
#[derive(Debug, Copy, Clone)]
struct a_t_64 {
    t: [f64; 60],
}

fn normalize_a_t(x: &mut videofft::a_t, mu: &a_t_64, sigma: &a_t_64) {
    for i in 0..60 {
        x.t[i] = (x.t[i] - (mu.t[i] as f32)) / (sigma.t[i] as f32);
    }
}

impl a_t_64 {
    fn take_sqrt(&mut self) {
        for i in 0..self.t.len() {
            self.t[i] = self.t[i].sqrt();
        }
    }

    fn add_unnormalized_sigma_2_self(&mut self, mu: &Self, other: &videofft::a_t) {
        for i in 0..self.t.len() {
            let d = (other.t[i] as f64) - mu.t[i];
            self.t[i] += d * d;
        }
    }

    fn add_2_self(&mut self, other: &videofft::a_t) {
        for i in 0..self.t.len() {
            self.t[i] += other.t[i] as f64;
        }
    }

    fn add_2_self_64(&mut self, other: &Self) {
        for i in 0..self.t.len() {
            self.t[i] += other.t[i] as f64;
        }
    }

    fn divide_self(&mut self, val: f64) {
        for i in 0..self.t.len() {
            self.t[i] /= val;
        }
    }

    fn new(val: f64) -> Self {
        Self { t: [val; 60] }
    }
}

impl Default for a_t_64 {
    fn default() -> Self {
        Self {
            t: [0.0 as f64; 60],
        }
    }
}

#[repr(C)]
#[derive(Debug, Copy, Clone)]
struct a_x_64 {
    x: [a_t_64; 160],
}

fn normalize_a_x(x: &mut videofft::a_x, mu: &a_x_64, sigma: &a_x_64) {
    for i in 0..160 {
        normalize_a_t(&mut x.x[i], &mu.x[i], &sigma.x[i]);
    }
}

impl Default for a_x_64 {
    fn default() -> Self {
        Self {
            x: [a_t_64::default(); 160],
        }
    }
}

impl a_x_64 {
    fn take_sqrt(&mut self) {
        for i in 0..self.x.len() {
            self.x[i].take_sqrt();
        }
    }

    fn add_unnormalized_sigma_2_self(&mut self, mu: &Self, other: &videofft::a_x) {
        for i in 0..self.x.len() {
            self.x[i].add_unnormalized_sigma_2_self(&(mu.x[i]), &(other.x[i]));
        }
    }

    fn add_2_self(&mut self, other: &videofft::a_x) {
        for i in 0..self.x.len() {
            self.x[i].add_2_self(&(other.x[i]));
        }
    }

    fn add_2_self_64(&mut self, other: &Self) {
        for i in 0..self.x.len() {
            self.x[i].add_2_self_64(&(other.x[i]));
        }
    }

    fn divide_self(&mut self, val: f64) {
        for i in 0..self.x.len() {
            self.x[i].divide_self(val);
        }
    }
}

#[repr(C)]
#[derive(Debug, Copy, Clone)]
struct a_y_64 {
    y: [a_x_64; 160],
}

fn normalize_a_y(x: &mut videofft::a_y, mu: &a_y_64, sigma: &a_y_64) {
    for i in 0..160 {
        normalize_a_x(&mut x.y[i], &mu.y[i], &sigma.y[i]);
    }
}

impl Default for a_y_64 {
    fn default() -> Self {
        Self {
            y: [a_x_64::default(); 160],
        }
    }
}

impl a_y_64 {
    fn take_sqrt(&mut self) {
        for i in 0..self.y.len() {
            self.y[i].take_sqrt();
        }
    }

    fn add_unnormalized_sigma_2_self(&mut self, mu: &Self, other: &videofft::a_y) {
        for i in 0..self.y.len() {
            self.y[i].add_unnormalized_sigma_2_self(&(mu.y[i]), &(other.y[i]));
        }
    }

    fn add_2_self(&mut self, other: &videofft::a_y) {
        for i in 0..self.y.len() {
            self.y[i].add_2_self(&(other.y[i]));
        }
    }

    fn add_2_self_64(&mut self, other: &Self) {
        for i in 0..self.y.len() {
            self.y[i].add_2_self_64(&(other.y[i]));
        }
    }

    fn divide_self(&mut self, val: f64) {
        for i in 0..self.y.len() {
            self.y[i].divide_self(val);
        }
    }
}

#[repr(C)]
#[derive(Debug, Copy, Clone)]
struct a_p_64 {
    p: [a_y_64; 6],
}

fn normalize_a_p(x: &mut videofft::a_p, mu: &a_p_64, sigma: &a_p_64) {
    for i in 0..6 {
        normalize_a_y(&mut x.p[i], &mu.p[i], &sigma.p[i]);
    }
}

impl Default for a_p_64 {
    fn default() -> Self {
        Self {
            p: [a_y_64::default(); 6],
        }
    }
}

impl a_p_64 {
    fn take_sqrt(&mut self) {
        for i in 0..self.p.len() {
            self.p[i].take_sqrt();
        }
    }

    fn add_unnormalized_sigma_2_self(&mut self, mu: &Self, other: &videofft::a_p) {
        for i in 0..self.p.len() {
            self.p[i].add_unnormalized_sigma_2_self(&(mu.p[i]), &(other.p[i]));
        }
    }

    fn add_2_self(&mut self, other: &videofft::a_p) {
        for i in 0..self.p.len() {
            self.p[i].add_2_self(&(other.p[i]));
        }
    }

    fn add_2_self_64(&mut self, other: &Self) {
        for i in 0..self.p.len() {
            self.p[i].add_2_self_64(&(other.p[i]));
        }
    }

    fn divide_self(&mut self, val: f64) {
        for i in 0..self.p.len() {
            self.p[i].divide_self(val);
        }
    }
}

#[repr(C)]
#[derive(Debug, Default, Clone)]
pub struct fft_video_64 {
    v: a_p_64,
}

fn normalize_fft_video(x: &mut videofft::fft_video, mu: &fft_video_64, sigma: &fft_video_64) {
    normalize_a_p(&mut x.v, &mu.v, &sigma.v);
}

impl fft_video_64 {
    fn take_sqrt(&mut self) {
        self.v.take_sqrt();
    }

    fn add_unnormalized_sigma_2_self(&mut self, mu: &Self, other: &videofft::fft_video) {
        self.v.add_unnormalized_sigma_2_self(&(mu.v), &(other.v));
    }

    fn add_2_self(&mut self, other: &videofft::fft_video) {
        self.v.add_2_self(&(other.v));
    }

    fn add_2_self_64(&mut self, other: &Self) {
        self.v.add_2_self_64(&(other.v));
    }

    fn divide_self(&mut self, val: f64) {
        self.v.divide_self(val);
    }

    pub async fn save(&self, filename: &str) -> anyhow::Result<()> {
        let size = std::mem::size_of::<Self>();
        let bytes = unsafe { std::slice::from_raw_parts((self as *const Self) as *const u8, size) };

        if false {
            let mut file = tokio::fs::File::create(filename).await?;
            file.write_all(bytes).await?;
        } else {
            tokio::fs::File::create(filename)
                .await?
                .write_all(bytes)
                .await?;
        }

        return Ok(());
    }
}

async fn eval_actual_mean(
    list_path_file_video_input: &[String],
) -> anyhow::Result<std::boxed::Box<fft_video_64>> {
    let mut accumulator: std::boxed::Box<fft_video_64> =
        std::boxed::Box::new(fft_video_64::default());

    for i in list_path_file_video_input {
        let data = tokio::fs::read(i.as_str()).await?;

        let data_fft: &videofft::fft_video =
            unsafe { &*(data.as_ptr() as *const videofft::fft_video) };

        accumulator.add_2_self(data_fft);
    }

    Ok(accumulator)
}

async fn eval_actual_sigma(
    list_path_file_video_input: &[String],
    mu: &fft_video_64,
) -> anyhow::Result<std::boxed::Box<fft_video_64>> {
    let mut accumulator: std::boxed::Box<fft_video_64> =
        std::boxed::Box::new(fft_video_64::default());

    for i in list_path_file_video_input {
        let data = tokio::fs::read(i.as_str()).await?;

        let data_fft: &videofft::fft_video =
            unsafe { &*(data.as_ptr() as *const videofft::fft_video) };

        accumulator.add_unnormalized_sigma_2_self(
            /* mu: &Self = */ mu, /* other: &videofft::fft_video = */ data_fft,
        );
    }

    Ok(accumulator)
}

pub async fn eval_mean(target_dir: &str) -> anyhow::Result<String> {
    let mut list_path_file_video: Vec<String> = vec![];

    if true {
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
    }

    const nthreads: usize = 16;
    const nchunks: usize = 1 << 12;

    let mut streams = vec![];
    for i in list_path_file_video.chunks(nchunks) {
        streams.push(eval_actual_mean(i));
    }

    let mut jobs = stream::iter(streams).buffer_unordered(nthreads);

    let path_file_mean_output = target_dir.to_string() + "_mean.64bin";

    if true {
        let mut accumulator: std::boxed::Box<fft_video_64> =
            std::boxed::Box::new(fft_video_64::default());

        while let Some(result) = jobs.next().await {
            let arr = result?;
            accumulator.add_2_self_64(&*arr);
        }

        accumulator.divide_self(list_path_file_video.len() as f64);

        if true {
            accumulator.save(path_file_mean_output.as_str()).await?;
        }
    }

    Ok(path_file_mean_output)
}

pub async fn eval_sigma(target_dir: &str, path_file_bin64_mean: &str) -> anyhow::Result<String> {
    let mut list_path_file_video: Vec<String> = vec![];

    if true {
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
    }

    const nthreads: usize = 16;
    const nchunks: usize = 1 << 12;

    let mean_data = tokio::fs::read(path_file_bin64_mean).await?;
    let mean = unsafe { &*(mean_data.as_ptr() as *const fft_video_64) };

    let mut streams = vec![];
    for i in list_path_file_video.chunks(nchunks) {
        streams.push(eval_actual_sigma(i, mean));
    }

    let mut jobs = stream::iter(streams).buffer_unordered(nthreads);

    let path_file_sigma_output = target_dir.to_string() + "_sigma.64bin";

    if true {
        let mut accumulator: std::boxed::Box<fft_video_64> =
            std::boxed::Box::new(fft_video_64::default());

        while let Some(result) = jobs.next().await {
            let arr = result?;
            accumulator.add_2_self_64(&*arr);
        }

        accumulator.divide_self(list_path_file_video.len() as f64);
        accumulator.take_sqrt();

        if true {
            accumulator.save(path_file_sigma_output.as_str()).await?;
        }
    }

    Ok(path_file_sigma_output)
}

pub async fn eval_mean_sigma_slave(path_dir_base: &str) -> anyhow::Result<()> {
    let path_file_64bin_mean = eval_mean(path_dir_base).await?;

    let path_file_64bin_sigma = eval_sigma(
        /* target_dir: &str = */ path_dir_base,
        /* path_file_bin64_mean: &str = */ path_file_64bin_mean.as_str(),
    )
    .await?;

    Ok(())
}

pub fn eval_mean_sigma(path_dir_base: &str) -> anyhow::Result<()> {
    let rt = tokio::runtime::Builder::new_multi_thread()
        .worker_threads(24)
        .enable_all()
        .build()?;

    rt.block_on(async {
        tokio::join!(eval_mean_sigma_slave(path_dir_base));
    });

    Ok(())
}

pub struct fft_video_normalizer {
    mu: fft_video_64,
    sigma: fft_video_64,
}

impl fft_video_normalizer {
    pub fn new(
        path_file_bin64_mu: &str,
        path_file_bin64_sigma: &str,
    ) -> anyhow::Result<std::boxed::Box<Self>> {
        let ret = std::boxed::Box::<Self>::new_uninit();
        const size: usize = std::mem::size_of::<fft_video_64>();

        {
            let mut file = std::fs::File::open(path_file_bin64_mu)?;
            let ptr = (&mut (unsafe { *ret.as_mut_ptr() }.mu) as *mut fft_video_64) as *mut u8;
            let buffer = unsafe { std::slice::from_raw_parts_mut(ptr, size) };
            file.read_exact(buffer)?;
        }

        {
            let mut file = std::fs::File::open(path_file_bin64_sigma)?;
            let ptr = (&mut (unsafe { *ret.as_mut_ptr() }.sigma) as *mut fft_video_64) as *mut u8;
            let buffer = unsafe { std::slice::from_raw_parts_mut(ptr, size) };
            file.read_exact(buffer)?;
        }
    }

    pub fn normalize(&self, x: &mut videofft::fft_video) {
        normalize_fft_video(
            /*x: &mut videofft::fft_video =*/ x,
            /*mu: &fft_video_64 =*/ &self.mu,
            /*sigma: &fft_video_64 =*/ &self.sigma,
        );
    }

    pub fn normalize_vec(&self, x: &mut Vec<videofft::fft_video>) {
        for i in x.iter_mut() {
            self.normalize(i);
        }
    }
}
