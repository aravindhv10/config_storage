use crate::videofn;

pub struct video_slicer {
    path_file_video_input: String,
    path_file_rawvideo_output: String,

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

impl Drop for video_slicer {
    fn drop(&mut self) {
        let _ = std::fs::remove_file(self.path_file_rawvideo_output.as_str());
    }
}

impl video_slicer {
    pub fn new(
        path_file_video_input: String,
        mut path_file_rawvideo_output: Option<String>,
        fps: f32,
        size_x: u16,
        size_y: u16,
        size_c: u8,
    ) -> anyhow::Result<Self> {
        if path_file_rawvideo_output.is_none() {
            let name_hash: u64 = videofn::get_str_hash(path_file_video_input.as_str());
            let hash: u64 = videofn::get_file_hash(path_file_video_input.as_str())?;
            path_file_rawvideo_output = Some(format!("/dev/shm/{:x}.{:x}.raw", name_hash, hash));
        }

        let path_file_rawvideo_output: String = path_file_rawvideo_output.unwrap();

        videofn::convert_encoded_video_to_raw(
            path_file_video_input.as_str(),
            path_file_rawvideo_output.as_str(),
            fps,
            size_x,
            size_y,
            size_c,
        )?;

        let file: std::fs::File = std::fs::File::open(path_file_rawvideo_output.as_str())?;
        let mmap: memmap2::Mmap =
            unsafe { memmap2::Mmap::map(&file).expect("failed to map the file") };

        let size_t: u16 =
            (mmap.len() / ((size_x as usize) * (size_y as usize) * (size_c as usize))) as u16;

        let dist_c: i32 = 1;

        let dist_c: usize = 1;
        let dist_x: usize = dist_c * (size_c as usize);
        let dist_y: usize = dist_x * (size_x as usize);
        let dist_t: usize = dist_y * (size_y as usize);

        let ret: Self = Self {
            path_file_video_input: path_file_video_input,
            path_file_rawvideo_output: path_file_rawvideo_output,
            fps: fps,

            size_x: size_x,
            size_y: size_y,
            size_c: size_c,
            size_t: size_t,

            dist_x: dist_x,
            dist_y: dist_y,
            dist_c: dist_c,
            dist_t: dist_t,

            mmap: mmap,
        };

        return Ok(ret);
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
