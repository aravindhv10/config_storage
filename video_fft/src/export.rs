pub type float32_t = f32;
pub type float64_t = f64;
pub type intype = u8;
pub type outtype = float32_t;

pub const INT8_MIN: i32 = -128;
pub const INT16_MIN: i32 = -32768;
pub const INT32_MIN: i32 = -2147483648;
pub const INT8_MAX: u32 = 127;
pub const INT16_MAX: u32 = 32767;
pub const INT32_MAX: u32 = 2147483647;
pub const UINT8_MAX: u32 = 255;
pub const UINT16_MAX: u32 = 65535;
pub const UINT32_MAX: u32 = 4294967295;
pub const INT_LEAST8_MIN: i32 = -128;
pub const INT_LEAST16_MIN: i32 = -32768;
pub const INT_LEAST32_MIN: i32 = -2147483648;
pub const INT_LEAST8_MAX: u32 = 127;
pub const INT_LEAST16_MAX: u32 = 32767;
pub const INT_LEAST32_MAX: u32 = 2147483647;
pub const UINT_LEAST8_MAX: u32 = 255;
pub const UINT_LEAST16_MAX: u32 = 65535;
pub const UINT_LEAST32_MAX: u32 = 4294967295;
pub const INT_FAST8_MIN: i32 = -128;
pub const INT_FAST16_MIN: i64 = -9223372036854775808;
pub const INT_FAST32_MIN: i64 = -9223372036854775808;
pub const INT_FAST8_MAX: u32 = 127;
pub const INT_FAST16_MAX: u64 = 9223372036854775807;
pub const INT_FAST32_MAX: u64 = 9223372036854775807;
pub const UINT_FAST8_MAX: u32 = 255;
pub const UINT_FAST16_MAX: i32 = -1;
pub const UINT_FAST32_MAX: i32 = -1;
pub const INTPTR_MIN: i64 = -9223372036854775808;
pub const INTPTR_MAX: u64 = 9223372036854775807;
pub const UINTPTR_MAX: i32 = -1;
pub const PTRDIFF_MIN: i64 = -9223372036854775808;
pub const PTRDIFF_MAX: u64 = 9223372036854775807;
pub const SIG_ATOMIC_MIN: i32 = -2147483648;
pub const SIG_ATOMIC_MAX: u32 = 2147483647;
pub const SIZE_MAX: i32 = -1;
pub const WINT_MIN: u32 = 0;
pub const WINT_MAX: u32 = 4294967295;
pub const INT8_WIDTH: u32 = 8;
pub const UINT8_WIDTH: u32 = 8;
pub const INT16_WIDTH: u32 = 16;
pub const UINT16_WIDTH: u32 = 16;
pub const INT32_WIDTH: u32 = 32;
pub const UINT32_WIDTH: u32 = 32;
pub const INT64_WIDTH: u32 = 64;
pub const UINT64_WIDTH: u32 = 64;
pub const INT_LEAST8_WIDTH: u32 = 8;
pub const UINT_LEAST8_WIDTH: u32 = 8;
pub const INT_LEAST16_WIDTH: u32 = 16;
pub const UINT_LEAST16_WIDTH: u32 = 16;
pub const INT_LEAST32_WIDTH: u32 = 32;
pub const UINT_LEAST32_WIDTH: u32 = 32;
pub const INT_LEAST64_WIDTH: u32 = 64;
pub const UINT_LEAST64_WIDTH: u32 = 64;
pub const INT_FAST8_WIDTH: u32 = 8;
pub const UINT_FAST8_WIDTH: u32 = 8;
pub const INT_FAST16_WIDTH: u32 = 64;
pub const UINT_FAST16_WIDTH: u32 = 64;
pub const INT_FAST32_WIDTH: u32 = 64;
pub const UINT_FAST32_WIDTH: u32 = 64;
pub const INT_FAST64_WIDTH: u32 = 64;
pub const UINT_FAST64_WIDTH: u32 = 64;
pub const INTPTR_WIDTH: u32 = 64;
pub const UINTPTR_WIDTH: u32 = 64;
pub const INTMAX_WIDTH: u32 = 64;
pub const UINTMAX_WIDTH: u32 = 64;
pub const PTRDIFF_WIDTH: u32 = 64;
pub const SIG_ATOMIC_WIDTH: u32 = 32;
pub const SIZE_WIDTH: u32 = 64;
pub const WCHAR_WIDTH: u32 = 32;
pub const WINT_WIDTH: u32 = 32;

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
