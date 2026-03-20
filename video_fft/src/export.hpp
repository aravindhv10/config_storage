#ifndef _HEADER_GUARD_src_export_hpp
#define _HEADER_GUARD_src_export_hpp

#include <stdint.h>

extern "C" {

using float32_t = float;
using float64_t = double;

using intype = unsigned char;
using outtype = float;

#include "./export.cpp"

} // extern "C"

#endif
