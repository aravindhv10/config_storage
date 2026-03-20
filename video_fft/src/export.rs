pub type float32_t = f32;
pub type float64_t = f64;

pub type intype = u8;
pub type outtype = float32_t;

unsafe extern "C" {
    pub fn do_fft_compress(
        blob: *mut ::std::os::raw::c_void,
        size_t: u16,
        size_y: u16,
        size_x: u16,
        size_c: u8,
        fps: float32_t,
        freq_limit: float32_t,
        dest: *mut ::std::os::raw::c_void,
    ) -> ::std::os::raw::c_int;
}

unsafe extern "C" {
    pub fn do_debug() -> ::std::os::raw::c_int;
}
