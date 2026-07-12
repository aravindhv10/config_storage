use crate::filestore;
use crate::hasher;

pub struct video_slicer_mapped {
    fps: f32,

    size_t: u16,
    size_x: u16,
    size_y: u16,
    size_c: u8,

    dist_t: usize,
    dist_x: usize,
    dist_y: usize,
    dist_c: usize,

    mmap: memmap2::Mmap,
}

impl video_slicer_mapped {
    pub fn new(
        mmap: memmap2::Mmap,
        fps: f32,
        size_x: u16,
        size_y: u16,
        size_c: u8,
    ) -> anyhow::Result<Self> {
        let size_t: u16 =
            (mmap.len() / ((size_x as usize) * (size_y as usize) * (size_c as usize))) as u16;

        let _dist_c: i32 = 1;

        let dist_c: usize = 1;
        let dist_x: usize = dist_c * (size_c as usize);
        let dist_y: usize = dist_x * (size_x as usize);
        let dist_t: usize = dist_y * (size_y as usize);

        Ok(Self {
            mmap: mmap,

            fps: fps,

            size_x: size_x,
            size_y: size_y,
            size_c: size_c,
            size_t: size_t,

            dist_x: dist_x,
            dist_y: dist_y,
            dist_c: dist_c,
            dist_t: dist_t,
        })
    }

    async fn new_from_key_value(
        key: &hasher::blob_hash,
        value: &Vec<u8>,
        fps: f32,
        size_x: u16,
        size_y: u16,
        size_c: u8,
    ) -> anyhow::Result<Self> {
        let res = filestore::file_store::new()
            .await?
            .get_tensor_from_video(key, value, fps, size_x, size_y)
            .await?;

        Self::new(res, fps, size_x, size_y, size_c)
    }

    #[inline(always)]
    fn get_size(&self, i: u8) -> usize {
        match i {
            0 => self.size_c as usize,
            1 => self.size_x as usize,
            2 => self.size_y as usize,
            3 => self.size_t as usize,
            _ => 1 as usize,
        }
    }

    #[inline(always)]
    fn get_dist(&self, i: u8) -> usize {
        match i {
            0 => self.dist_c,
            1 => self.dist_x,
            2 => self.dist_y,
            3 => self.dist_t,
            _ => self.mmap.len(),
        }
    }

    pub fn get_video_tensor(&self) -> anyhow::Result<tch::Tensor> {
        if self.size_t < 2 {
            return Err(anyhow::format_err!("The video blob seems too small"));
        }

        let data: *const u8 = self.mmap.as_ptr();

        let size: [i64; 4] = [
            self.get_size(3) as i64,
            self.get_size(2) as i64,
            self.get_size(1) as i64,
            self.get_size(0) as i64,
        ];

        let strides: [i64; 4] = [
            self.get_dist(3) as i64,
            self.get_dist(2) as i64,
            self.get_dist(1) as i64,
            self.get_dist(0) as i64,
        ];

        let tensor_data: tch::Tensor = unsafe {
            tch::Tensor::from_blob(
                /* data = */ data,
                /* size = */ &size,
                /* strides = */ &strides,
                tch::Kind::Uint8,
                tch::Device::Cpu,
            )
        };

        return Ok(tensor_data);
    }
}
