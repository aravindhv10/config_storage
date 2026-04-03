pub type float32_t = f32;
pub type float64_t = f64;

pub type intype = u8;
pub type outtype = float32_t;

unsafe extern "C" {
    pub fn new_infer_slave(batch_size: ::std::os::raw::c_uchar) -> *mut ::std::os::raw::c_void;
    pub fn delete_infer_slave(in_: *mut ::std::os::raw::c_void);
    pub fn run_infer_slave(
        in_: *mut ::std::os::raw::c_void,
        blob_source: *mut ::std::os::raw::c_void,
        blob_destination: *mut ::std::os::raw::c_void,
    );
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
