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

inline torch::Tensor do_pad_video(torch::Tensor & tensor_input) {
  auto size = tensor_input.sizes();
  auto h = size[1];
  auto w = size[1];
  if (h<w) {
    return torch::nn::functional::pad(tensor_input, torch::ArrayRef<long>({0, 0, 0, 0, 0, w - h}));
  } else if (w<h) {
    return torch::nn::functional::pad(tensor_input, torch::ArrayRef<long>({0, 0, 0, h-w, 0, 0}));
  } else {
    return tensor_input.detach();
  }
}

int do_fft_compress(void *blob, int len_t, int len_y, int len_x, int len_c,
                    float fps, float freq_limit, void *dest) {

  int64_t dist_c = 1;
  int64_t dist_x = len_c * dist_c;
  int64_t dist_y = len_x * dist_x;
  int64_t dist_t = len_y * dist_y;

  auto good_device_and_dtype = get_good_device_and_dtype();

  torch::Tensor tensor_video_padded;

  if (true) {
    torch::Tensor tensor_video = torch::from_blob(
        blob, {len_t, len_y, len_x, len_c}, {dist_t, dist_y, dist_x, dist_t},
        get_host_input_device_and_dtype());

    tensor_video_padded = do_pad_video(/*torch::Tensor & tensor_input =*/ tensor_video).to(good_device_and_dtype) ;
  }

  std::cout << tensor_video_padded;

  float32_t passed = 0;
  if (true) {

    auto freq =
        torch::fft::rfftfreq(len_t, torch::TensorOptions()
                                         .dtype(get_tensor_dtype<float32_t>())
                                         .device(torch::kCPU)) *
        fps;

    passed = torch::sum(freq < freq_limit).item().to<float32_t>();
  }

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
