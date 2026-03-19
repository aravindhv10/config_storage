#ifndef _HEADER_GUARD_src_export_hpp
#define _HEADER_GUARD_src_export_hpp
extern "C" {

using float32_t = float;
using float64_t = double;
using int16_t = short int;
using int32_t = int;
using int64_t = long;
using int8_t = char;
using uint16_t = unsigned short int;
using uint32_t = unsigned int;
using uint64_t = unsigned long;
using uint8_t = unsigned char;

int do_fft_compress(void *blob, uint16_t size_t, uint16_t size_y,
                    uint16_t size_x, uint8_t size_c, float32_t fps,
                    float32_t freq_limit, void *dest);

int do_debug() {
  do_fft_compress(/*void *blob =*/ NULL,
                  /*uint16_t size_t =*/ 100,
                  /*uint16_t size_y =*/ 10,
                  /*uint16_t size_x =*/ 10,
                  /*uint8_t size_c =*/ 3,
                  /*float32_t fps =*/ 8.0,
                  /*float32_t freq_limit =*/ 3.0,
                  /*void *dest =*/ NULL);
}

} // extern "C"
#endif
