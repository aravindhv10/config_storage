use crate::videofn;

pub struct video_slicer {
    path_file_video_input: std::path::PathBuf,
    path_file_rawvideo_output: std::path::PathBuf,

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
        let _ = std::fs::remove_file(&(self.path_file_rawvideo_output));
    }
}

impl video_slicer {
    pub fn new(
        path_file_video_input: impl AsRef<std::path::Path>,
        mut path_file_rawvideo_output: Option<std::path::PathBuf>,
        fps: f32,
        size_x: u16,
        size_y: u16,
        size_c: u8,
    ) -> anyhow::Result<Self> {
        if path_file_rawvideo_output.is_none() {
            let name_hash = videofn::get_path_hash(path_file_video_input.as_ref());
            let hash = videofn::get_file_hash(path_file_video_input.as_ref())?;
            let tmppath = std::path::PathBuf::from(format!(
                "/dev/shm/{}.{}.raw",
                name_hash.get_hash_string(),
                hash.get_hash_string()
            ));
            path_file_rawvideo_output = Some(tmppath);
        }

        let path_file_rawvideo_output: std::path::PathBuf = path_file_rawvideo_output.unwrap();

        videofn::convert_encoded_video_to_raw(
            &path_file_video_input,
            &path_file_rawvideo_output,
            fps,
            size_x,
            size_y,
            size_c,
        )?;

        let file: std::fs::File = std::fs::File::open(&path_file_rawvideo_output)?;
        let mmap_result = unsafe { memmap2::Mmap::map(&file) };
        let _ = std::fs::remove_file(&path_file_rawvideo_output);
        let mmap: memmap2::Mmap = mmap_result?;

        let size_t: u16 =
            (mmap.len() / ((size_x as usize) * (size_y as usize) * (size_c as usize))) as u16;

        let dist_c: i32 = 1;

        let dist_c: usize = 1;
        let dist_x: usize = dist_c * (size_c as usize);
        let dist_y: usize = dist_x * (size_x as usize);
        let dist_t: usize = dist_y * (size_y as usize);

        let ret: Self = Self {
            path_file_video_input: path_file_video_input.as_ref().to_path_buf(),
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

pub struct video_slicer_piped {
    fps: f32,

    size_t: u16,
    size_x: u16,
    size_y: u16,
    size_c: u8,

    dist_t: usize,
    dist_x: usize,
    dist_y: usize,
    dist_c: usize,

    raw_video: Vec<u8>,
}

impl video_slicer_piped {
    pub fn new(
        path_file_video_input: impl AsRef<std::path::Path>,
        fps: f32,
        size_x: u16,
        size_y: u16,
        size_c: u8,
        clean_video: bool,
    ) -> anyhow::Result<Self> {
        let raw_video = videofn::convert_encoded_video_to_raw_outpipe(
            /*path_file_video_input: &str =*/ path_file_video_input.as_ref(),
            /*fps: f32 =*/ fps as f32,
            /*size_x: u16 =*/ size_x as u16,
            /*size_y: u16 =*/ size_y as u16,
            /*size_c: u8 =*/ size_c as u8,
            /*clean_video: bool =*/ clean_video as bool,
        )?;

        let size_t: u16 =
            (raw_video.len() / ((size_x as usize) * (size_y as usize) * (size_c as usize))) as u16;

        let dist_c: i32 = 1;

        let dist_c: usize = 1;
        let dist_x: usize = dist_c * (size_c as usize);
        let dist_y: usize = dist_x * (size_x as usize);
        let dist_t: usize = dist_y * (size_y as usize);

        let ret: Self = Self {
            fps: fps,

            size_t: size_t,
            size_x: size_x,
            size_y: size_y,
            size_c: size_c,

            dist_t: dist_t,
            dist_x: dist_x,
            dist_y: dist_y,
            dist_c: dist_c,

            raw_video: raw_video,
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
            _ => self.raw_video.len(),
        }
    }

    pub fn get_video_tensor(&self) -> anyhow::Result<tch::Tensor> {
        if self.size_t < 2 {
            return Err(anyhow::format_err!("The video blob seems too small"));
        }

        let data: *const u8 = self.raw_video.as_ptr();

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
                /* data = */ self.raw_video.as_ptr(),
                /* size = */ &size,
                /* strides = */ &strides,
                tch::Kind::Uint8,
                tch::Device::Cpu,
            )
        };

        return Ok(tensor_data);
    }
}
