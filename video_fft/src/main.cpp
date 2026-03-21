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

inline torch::TensorOptions get_good_device_and_dtype_old() {
  printf("Called get_good_device_and_dtype()\n");
  if (torch::cuda::is_available()) {
    printf("Returning cuda\n");
    return torch::TensorOptions().dtype(torch::kBFloat16).device(torch::kCUDA);
  } else {
    printf("Returning cpu\n");
    return torch::TensorOptions().dtype(torch::kBFloat16).device(torch::kCPU);
  }
}

inline torch::TensorOptions get_good_device_and_dtype() {
  printf("Called get_good_device_and_dtype()\n");
  return torch::TensorOptions().dtype(torch::kFloat32).device(torch::kCPU);
}

inline torch::TensorOptions get_host_input_device_and_dtype() {
  printf("Called get_host_input_device_and_dtype()\n");
  return torch::TensorOptions()
      .dtype(get_tensor_dtype<uint8_t>())
      .device(torch::kCPU);
}

inline torch::TensorOptions get_host_output_device_and_dtype() {
  printf("get_host_output_device_and_dtype started\n");
  return torch::TensorOptions()
      .dtype(get_tensor_dtype<float32_t>())
      .device(torch::kCPU);
}

inline torch::Tensor do_pad_video(torch::Tensor tensor_input) {
  auto size = tensor_input.sizes();
  auto h = size[1];
  auto w = size[2];
  if (h<w) {
    return  torch::nn::functional::pad(tensor_input, torch::nn::functional::PadFuncOptions({0, 0, 0, 0, 0, w - h}));
  } else if (w<h) {
    return  torch::nn::functional::pad(tensor_input, torch::nn::functional::PadFuncOptions({0, 0, 0, h-w, 0, 0}));
  } else {
    return tensor_input.detach();
  }
}

extern "C" {
int do_fft_compress_efficient(void *const blob, uint16_t const len_t,
                              uint16_t const len_y, uint16_t const len_x,
                              uint8_t const len_c, float32_t const fps,
                              float32_t const freq_limit, void *const dest,
                              bool use_gpu) {

  uint16_t len_max, len_min;
  if (len_x > len_y) {
    len_max = len_x;
    len_min = len_y;
  } else {
    len_max = len_y;
    len_min = len_x;
  }

  auto device_gpu = use_gpu ? torch::kCUDA : torch::kCPU;

  uint16_t const len_diff = len_max - len_max;
  uint16_t const len_truncated = len_max >> 3;

  uint16_t const position_start = (len_max - len_truncated) >> 1;
  uint16_t const position_end = position_start + len_truncated;

  int64_t const dist_c = 1;
  int64_t const dist_x = len_c * dist_c;
  int64_t const dist_y = len_x * dist_x;
  int64_t const dist_t = len_y * dist_y;

  " Initialize the tensor: ";
  torch::Tensor tensor_video_padded =
      torch::from_blob(
          /* data = */ blob,
          /* sizes = */ {len_t, len_y, len_x, len_c},
          /* strides = */ {dist_t, dist_y, dist_x, dist_c},
          /* Device_DType = */
          torch::TensorOptions()
              .dtype(get_tensor_dtype<uint8_t>())
              .device(torch::kCPU)) /* T H W C */
          .to(device_gpu);
  " T0 H1 W2 C3 ";

  " STEP 1 THWC => HWCT: ";
  " T0 H1 W2 C3 ";
  tensor_video_padded =
      do_pad_video(tensor_video_padded)
          .permute(/*dims =*/{1, 2, 3, 0}) /* T0 H1 W2 C3 -> H1 W2 C3 T0 */
          .to(torch::TensorOptions().dtype(torch::kFloat32).device(device_gpu));
  " H1 W2 C3 T0 ";

  " STEP 2 CHWT | RFFT => TCHW ";
  " C0 H1 W2 T3 ";
  tensor_video_padded =
      torch::fft::rfft(tensor_video_padded)
          .permute(/*dims =*/{3, 0, 1, 2}) /* C0 H1 W2 T3 -> T3 C0 H1 W2 */;
  " T3 C0 H1 W2 ";

  " STEP 3 TCHW | FFT => TWCH ";
  " T0 C1 H2 W3 ";
  tensor_video_padded =
      torch::fft::fft(tensor_video_padded)
          .permute(/*dims =*/{0, 1, 3, 2}) /* T0 C1 H2 W3 -> T0 C1 W3 H2 */;
  " T0 C1 W3 H2 ";

  " STEP 4 TCWH | FFT => THWC ";
  " T0 C1 W2 H3 ";
  tensor_video_padded =
      torch::fft::fft(tensor_video_padded)
          .permute(/*dims =*/{0, 1, 3, 2}) /* T0 C1 W2 H3 -> T0 C1 W3 H2 */;
  " T0 W3 H2 C1 ";

  " C0 H1 W2 T3 ";
  torch::Tensor tensor_video_padded =
      torch::fft::rfft(
          do_pad_video(/* torch::Tensor tensor_input = */
                       torch::from_blob(
                           /* data = */ blob,
                           /* sizes = */ {len_t, len_y, len_x, len_c},
                           /* strides = */ {dist_t, dist_y, dist_x, dist_c},
                           /* Device_DType = */
                           torch::TensorOptions()
                               .dtype(get_tensor_dtype<uint8_t>())
                               .device(torch::kCPU)))
              .permute(/*dims =*/{3, 1, 2, 0}) /* T0 H1 W2 C3 -> C3 H1 W2 T0 */
              .to(torch::TensorOptions()
                      .dtype(torch::kFloat32)
                      .device(device_gpu)))
          .permute(/*dims =*/{3, 0, 1, 2}) /* C0 H1 W2 T3 -> T3 C0 H1 W2 */;
  " T3 C0 H1 W2 ";

  " T0 C1 W2 H3 ";
  tensor_video_padded =
      torch::fft::fft(tensor_video_padded).permute(/*dims =*/{0, 2, 3, 1});
  " T0 W2 H3 C1 ";

  " T0 W1 H2 C3 ";
  tensor_video_padded =
      torch::fft::fft(tensor_video_padded).permute(/*dims =*/{3, 2, 1, 0});
  " C3 H2 W1 T0 ";

  torch::Tensor compressed_tensor_video_fft =
      torch::nn::functional::interpolate(
          torch::cat(
              {tensor_video_padded.abs(), tensor_video_padded.angle()},
              /*dim=*/0) /* Done extracting abs and angle into real tensor*/
              .unsqueeze(0),
          torch::nn::functional::InterpolateFuncOptions()
              .size(std::vector<int64_t>(
                  {len_truncated, len_truncated, static_cast<int64_t>(60)}))
              .mode(torch::kTrilinear)
              .align_corners(false)) /* Done interpolating */
          .squeeze()
          .to(torch::kCPU)
          .contiguous();

  std::memcpy(dest, compressed_tensor_video_fft.data_ptr(),
              compressed_tensor_video_fft.nbytes());

  return 0;
}
}

extern "C" {
int do_fft_compress(void *const blob, uint16_t const len_t,
                    uint16_t const len_y, uint16_t const len_x,
                    uint8_t const len_c, float32_t const fps,
                    float32_t const freq_limit, void *const dest,
                    bool use_gpu) {

  uint16_t len_max, len_min;
  if (len_x > len_y) {
    len_max = len_x;
    len_min = len_y;
  } else {
    len_max = len_y;
    len_min = len_x;
  }

  auto device_gpu = use_gpu ? torch::kCUDA : torch::kCPU;

  uint16_t const len_diff = len_max - len_max;
  uint16_t const len_truncated = len_max >> 3;

  uint16_t const position_start = (len_max - len_truncated) >> 1;
  uint16_t const position_end = position_start + len_truncated;

  int64_t const dist_c = 1;
  int64_t const dist_x = len_c * dist_c;
  int64_t const dist_y = len_x * dist_x;
  int64_t const dist_t = len_y * dist_y;

  torch::Tensor tensor_video_padded =
      torch::fft::fftshift(
          torch::fft::rfftn(
              do_pad_video(
                  torch::from_blob(
                      /* data = */ blob,
                      /* sizes = */ {len_t, len_y, len_x, len_c},
                      /* strides = */ {dist_t, dist_y, dist_x, dist_c},
                      /* Device_DType = */
                      torch::TensorOptions()
                          .dtype(get_tensor_dtype<uint8_t>())
                          .device(
                              torch::kCPU)) /* Done construction from blob */
                  )
                  .permute(
                      /*dims =*/{3, 1, 2, 0})
                  .to(torch::TensorOptions()
                          .dtype(torch::kFloat32)
                          .device(device_gpu))) /* Done RFFT */
              .narrow(
                  3, 0,
                  torch::sum(
                      (torch::fft::rfftfreq(
                           len_t, torch::TensorOptions()
                                      .dtype(get_tensor_dtype<float32_t>())
                                      .device(torch::kCPU)) *
                       fps) /* Scaled frequency mode range tensor */
                      <
                      freq_limit) /* Done evaluating number of modes to keep */
                      .item()
                      .to<uint16_t>()) /* Done truncation along time */,
          /* fftshift_dims = */ {0, 1, 2}) /* Done shifting the origin */
          .index({torch::indexing::Slice(),
                  torch::indexing::Slice(position_start, position_end),
                  torch::indexing::Slice(position_start, position_end),
                  torch::indexing::
                      Slice()}) /* Done truncating spatial dimensions */;

  torch::Tensor compressed_tensor_video_fft =
      torch::nn::functional::interpolate(
          torch::cat(
              {tensor_video_padded.abs(), tensor_video_padded.angle()},
              /*dim=*/0) /* Done extracting abs and angle into real tensor*/
              .unsqueeze(0),
          torch::nn::functional::InterpolateFuncOptions()
              .size(std::vector<int64_t>(
                  {len_truncated, len_truncated, static_cast<int64_t>(60)}))
              .mode(torch::kTrilinear)
              .align_corners(false)) /* Done interpolating */
          .squeeze()
          .to(torch::kCPU)
          .contiguous();

  std::memcpy(dest, compressed_tensor_video_fft.data_ptr(),
              compressed_tensor_video_fft.nbytes());

  return 0;
}
}
