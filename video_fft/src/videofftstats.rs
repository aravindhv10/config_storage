use crate::videofft;
use futures::stream;
use futures::stream::StreamExt;
use tokio::io::AsyncWriteExt;

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

    fn add_2_self(&mut self, other: &videofft::fft_video) {
        self.v.add_2_self(&(other.v));
    }

    fn add_2_self_64(&mut self, other: &Self) {
        self.v.add_2_self_64(&(other.v));
    }

    fn divide_self(&mut self, val: f64) {
        self.v.divide_self(val);
    }
}

async fn eval_actual_sum(
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

pub async fn eval_mean(target_dir: &str) -> anyhow::Result<()> {
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
        streams.push(eval_actual_sum(i));
    }

    let mut jobs = stream::iter(streams).buffer_unordered(nthreads);

    if true {
        let mut accumulator: std::boxed::Box<fft_video_64> =
            std::boxed::Box::new(fft_video_64::default());

        while let Some(result) = jobs.next().await {
            let arr = result?;
            accumulator.add_2_self_64(&*arr);
        }

        accumulator.divide_self(list_path_file_video.len() as f64);

        if true {
            let path_file_mean_output = target_dir.to_string() + "_mean.bin";
            accumulator.save(path_file_mean_output.as_str());
        }

        println!("{:?}", accumulator);
    }

    Ok(())
}
