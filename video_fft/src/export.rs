pub type float32_t = f32;
pub type float64_t = f64;

pub type intype = u8;
pub type outtype = float32_t;

pub const IMAGE_RESOLUTION: u32 = 448;
pub const NUM_CHANNELS: u32 = 3;
pub const IMAGE_SIZE: u32 = IMAGE_RESOLUTION * IMAGE_RESOLUTION * NUM_CHANNELS;

pub const NUM_CLASSES: u32 = 5;

unsafe extern "C" {
    pub fn unnamed_semaphore_new(num: ::std::os::raw::c_int) -> *mut ::std::os::raw::c_void;
    pub fn unnamed_semaphore_delete(in_: *mut ::std::os::raw::c_void);
    pub fn unnamed_semaphore_l(in_: *mut ::std::os::raw::c_void);
    pub fn unnamed_semaphore_r(in_: *mut ::std::os::raw::c_void);
}

unsafe extern "C" {
    pub fn named_semaphore_new(
        name: *const ::std::os::raw::c_char,
        num: ::std::os::raw::c_int,
    ) -> *mut ::std::os::raw::c_void;

    pub fn named_semaphore_delete(in_: *mut ::std::os::raw::c_void);

    pub fn named_semaphore_l(in_: *mut ::std::os::raw::c_void);

    pub fn named_semaphore_r(in_: *mut ::std::os::raw::c_void);
}

unsafe extern "C" {
    pub fn locker_to_inference_mode();
    pub fn locker_to_preprocessing_mode();
}

unsafe extern "C" {
    pub fn do_fft_compress_efficient(
        blob: *mut ::std::os::raw::c_void,
        len_t: u16,
        len_y: u16,
        len_x: u16,
        len_c: u8,
        fps: float32_t,
        freq_limit: float32_t,
        dest: *mut ::std::os::raw::c_void,
        use_gpu: bool,
    ) -> ::std::os::raw::c_int;
}

unsafe extern "C" {
    pub fn clear_cuda_cache();
}

unsafe extern "C" {
    pub fn new_infer_slave_image_cv_usability(
        batch_size: ::std::os::raw::c_uchar,
    ) -> *mut ::std::os::raw::c_void;
    pub fn delete_infer_slave_image_cv_usability(in_: *mut ::std::os::raw::c_void);
    pub fn run_infer_slave_image_cv_usability(
        in_: *mut ::std::os::raw::c_void,
        blob_source: *mut ::std::os::raw::c_void,
        blob_destination: *mut ::std::os::raw::c_void,
    ) -> ::std::os::raw::c_int;
}

unsafe extern "C" {
    pub fn new_infer_slave_image(
        batch_size: ::std::os::raw::c_uchar,
    ) -> *mut ::std::os::raw::c_void;
    pub fn delete_infer_slave_image(in_: *mut ::std::os::raw::c_void);
    pub fn run_infer_slave_image(
        in_: *mut ::std::os::raw::c_void,
        blob_source: *mut ::std::os::raw::c_void,
        blob_destination: *mut ::std::os::raw::c_void,
    ) -> ::std::os::raw::c_int;
}

unsafe extern "C" {
    pub fn new_infer_slave(batch_size: ::std::os::raw::c_uchar) -> *mut ::std::os::raw::c_void;
    pub fn delete_infer_slave(in_: *mut ::std::os::raw::c_void);
    pub fn run_infer_slave(
        in_: *mut ::std::os::raw::c_void,
        blob_source: *mut ::std::os::raw::c_void,
        blob_destination: *mut ::std::os::raw::c_void,
    ) -> ::std::os::raw::c_int;
}
