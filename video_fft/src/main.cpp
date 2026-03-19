#include "./main.hpp"

template <typename T> inline torch::ScalarType get_tensor_dtype() {return torch::kBFloat16;}
template <> inline torch::ScalarType get_tensor_dtype<float32_t>() {return torch::kFloat32;}
template <> inline torch::ScalarType get_tensor_dtype<float64_t>() {return torch::kFloat64;}
template <> inline torch::ScalarType get_tensor_dtype<int16_t>() { return torch::kInt16; }
template <> inline torch::ScalarType get_tensor_dtype<int32_t>() { return torch::kInt32; }
template <> inline torch::ScalarType get_tensor_dtype<int64_t>() { return torch::kInt64; }
template <> inline torch::ScalarType get_tensor_dtype<int8_t>() { return torch::kInt8; }
template <> inline torch::ScalarType get_tensor_dtype<uint16_t>() { return torch::kUInt16; }
template <> inline torch::ScalarType get_tensor_dtype<uint32_t>() { return torch::kUInt32; }
template <> inline torch::ScalarType get_tensor_dtype<uint64_t>() { return torch::kInt64; }
template <> inline torch::ScalarType get_tensor_dtype<uint8_t>() { return torch::kUInt8; }

inline torch::TensorOptions get_good_device_and_dtype() {
  printf("Called get_good_device_and_dtype()\n");
  if (torch::cuda::is_available()) {
    printf("Returning cuda\n");
    return torch::TensorOptions().dtype(torch::kBFloat16).device(torch::kCUDA);
  } else {
    printf("Returning cpu\n");
    return torch::TensorOptions().dtype(torch::kBFloat16).device(torch::kCPU);
  }
}

inline torch::TensorOptions get_host_input_device_and_dtype() {
  printf("Called get_host_input_device_and_dtype()\n");
  return torch::TensorOptions()
      .dtype(get_tensor_dtype<intype>())
      .device(torch::kCPU);
}

inline torch::TensorOptions get_host_output_device_and_dtype() {
  printf("get_host_output_device_and_dtype started\n");
  return torch::TensorOptions()
      .dtype(get_tensor_dtype<outtype>())
      .device(torch::kCPU);
}

int do_fft_compress(void *blob, int size_t, int size_y, int size_x, int size_c,
                    float fps, float freq_limit, void *dest) {
  auto freq =
      torch::fft::rfftfreq(size_t, torch::TensorOptions()
                                       .dtype(get_tensor_dtype<float32_t>())
                                       .device(torch::kCPU)) *
      fps;

  auto passed = torch::sum(freq < freq_limit);

  std::cout << passed;

  return 0;
}

int do_debug() {
    do_fft_compress(/*void *blob =*/ NULL,
                    /*uint16_t size_t =*/ 100,
                    /*uint16_t size_y =*/ 10,
                    /*uint16_t size_x =*/ 10,
                    /*uint8_t size_c =*/ 3,
                    /*float32_t fps =*/ 8.0,
                    /*float32_t freq_limit =*/ 3.0,
                    /*void *dest =*/ NULL);
    return 0;
}
