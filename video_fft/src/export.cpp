using float32_t = float;
using float64_t = double;

using intype = unsigned char;
using outtype = float;

int do_fft_compress_efficient(void *const blob, uint16_t const len_t,
                              uint16_t const len_y, uint16_t const len_x,
                              uint8_t const len_c, float32_t const fps,
                              float32_t const freq_limit, void *const dest,
                              bool use_gpu);

int do_fft_compress(void *const blob, uint16_t const len_t,
                    uint16_t const len_y, uint16_t const len_x,
                    uint8_t const len_c, float32_t const fps,
                    float32_t const freq_limit, void *const dest, bool use_gpu);
