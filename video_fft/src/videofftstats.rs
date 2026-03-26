use crate::videofft;
use futures::stream;
use futures::stream::StreamExt;
use tokio::io::AsyncWriteExt;

#[repr(C)]
#[derive(Debug, Copy, Clone)]
struct a_t_64 {
    t: [f64; 60],
}

impl a_t_64 {
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

impl Default for a_x_64 {
    fn default() -> Self {
        Self {
            x: [a_t_64::default(); 160],
        }
    }
}

impl a_x_64 {
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

impl Default for a_y_64 {
    fn default() -> Self {
        Self {
            y: [a_x_64::default(); 160],
        }
    }
}

impl a_y_64 {
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

impl Default for a_p_64 {
    fn default() -> Self {
        Self {
            p: [a_y_64::default(); 6],
        }
    }
}

impl a_p_64 {
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

impl fft_video_64 {
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
            /* mu: &Self = */ fft_video_64,
            /* other: &videofft::fft_video = */ data_fft,
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
    let mean = &unsafe { *(mean_data.as_ptr() as *const fft_video_64) };

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

        if true {
            accumulator.save(path_file_sigma_output.as_str()).await?;
        }
    }

    Ok(path_file_sigma_output)
}

pub fn eval_mean_sigma(path_dir_base: &str) -> anyhow::Result<()> {
    let rt = tokio::runtime::Builder::new_multi_thread()
        .worker_threads(24)
        .enable_all()
        .build()?;

    rt.block_on(async {
        let path_file_64bin_mean = tokio::join!(eval_mean(path_dir_base)).0?;

        let path_file_64bin_sigma = tokio::join!(eval_sigma(
            /* target_dir: &str = */ path_dir_base,
            /* path_file_bin64_mean: &str = */ path_file_64bin_mean.as_str()
        ))
        .0?;
    });

    Ok(())
}
