#include "./main.hpp"

inline torch::TensorOptions get_input_device_and_dtype() {
  printf("Called get_host_input_device_and_dtype()\n");
  return torch::TensorOptions().dtype(torch::kFloat32).device(torch::kCPU);
}

inline torch::TensorOptions get_inference_device_and_dtype() {
  printf("Called get_good_device_and_dtype()\n");
  if (torch::cuda::is_available()) {
    printf("Returning cuda\n");
    return torch::TensorOptions().dtype(torch::kFloat32).device(torch::kCUDA);
  } else {
    printf("Returning cpu\n");
    return torch::TensorOptions().dtype(torch::kFloat32).device(torch::kCPU);
  }
}

inline torch::TensorOptions get_output_device_and_dtype() {
  printf("get_host_output_device_and_dtype started\n");
  return torch::TensorOptions().dtype(torch::kFloat32).device(torch::kCPU);
}

class gpu_locker {

private:
  sem_t *gpu_semaphore;

public:
  gpu_locker() : gpu_semaphore(sem_open("/gpuLock", O_CREAT, S_IRWXU, 2)) {}
  ~gpu_locker() { sem_close(gpu_semaphore); }

  inline void l() { sem_wait(gpu_semaphore); }
  inline void r() {
    sem_post(gpu_semaphore);
    c10::cuda::CUDACachingAllocator::emptyCache();
  }
};

static gpu_locker locker;

#define _MACRO_SELF_ infer_slave

class _MACRO_SELF_ {
private:
  torch::TensorOptions options_input;
  torch::TensorOptions options_compute;
  torch::TensorOptions options_output;

  torch::inductor::AOTIModelPackageLoader loader;
  std::size_t batch_size;
  std::size_t bytes_to_copy;

  c10::InferenceMode mode;

public:
  inline void infer(void *blob_source, void *blob_destination) {

    torch::Tensor cpu_tensor = torch::from_blob(
        blob_source, {static_cast<long>(batch_size), 6, 160, 160, 60},
        options_input);

    std::vector<torch::Tensor> inputs = {cpu_tensor.to(options_compute)};

    std::vector<torch::Tensor> outputs = loader.run(inputs);

    torch::Tensor out_tensor = outputs[0].to(options_output).contiguous();

    std::memcpy(blob_destination, out_tensor.const_data_ptr(), bytes_to_copy);
  }

  _MACRO_SELF_(std::string const path_file_model, std::size_t BATCH_SIZE)
      : options_input(get_input_device_and_dtype()),
        options_compute(get_inference_device_and_dtype()),
        options_output(get_output_device_and_dtype()), loader(path_file_model),
        batch_size(BATCH_SIZE),
        bytes_to_copy(batch_size * 3 * sizeof(outtype)) {
    locker.l();
  }

  ~_MACRO_SELF_() { locker.r(); }

  inline static _MACRO_SELF_ *NEW(std::size_t BATCH_SIZE) {
    BATCH_SIZE = std::min(BATCH_SIZE, static_cast<std::size_t>(4));
    std::string path_file_model("/root/.cache/model_6.pt2");
    path_file_model[19] = '0' + BATCH_SIZE;
    std::cout << "Checkpoint path: " << path_file_model << std::endl;
    return new _MACRO_SELF_(path_file_model, BATCH_SIZE);
  }
};

extern "C" {
void *new_infer_slave(unsigned char batch_size) {
  return static_cast<void *>(
      _MACRO_SELF_::NEW(static_cast<size_t>(batch_size)));
}

void delete_infer_slave(void *in) {
  _MACRO_SELF_ *tmp = static_cast<_MACRO_SELF_ *>(in);
  delete tmp;
}

void run_infer_slave(void *in, void *blob_source, void *blob_destination) {
  _MACRO_SELF_ *tmp = static_cast<_MACRO_SELF_ *>(in);

  tmp->infer(/*void *blob_source =*/blob_source,
             /*void *blob_destination =*/blob_destination);
}
}

#undef _MACRO_SELF_

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

  try {

    uint16_t len_max, len_min;
    if (len_x > len_y) {
      len_max = len_x;
      len_min = len_y;
    } else {
      len_max = len_y;
      len_min = len_x;
    }

    auto device_gpu = use_gpu ? torch::kCUDA : torch::kCPU;

    uint16_t const len_diff = len_max - len_min;
    uint16_t const len_truncated = len_max >> 3;

    uint16_t const position_start = (len_max - len_truncated) >> 1;
    uint16_t const position_end = position_start + len_truncated;

    int64_t const dist_c = 1;
    int64_t const dist_x = len_c * dist_c;
    int64_t const dist_y = len_x * dist_x;
    int64_t const dist_t = len_y * dist_y;

    auto t_cutoff =
        torch::sum((torch::fft::rfftfreq(
                        len_t, torch::TensorOptions()
                                   .dtype(get_tensor_dtype<float32_t>())
                                   .device(torch::kCPU)) *
                    fps)         /* Scaled frequency mode range tensor */
                   < freq_limit) /* Done evaluating number of modes to keep */
            .item()
            .to<uint16_t>();

    locker.l();

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

    tensor_video_padded = do_pad_video(tensor_video_padded)
                              .to(torch::kFloat32)
                              .permute({3, 1, 2, 0});

    if (true) {
      int64_t constexpr i = 3;

      tensor_video_padded =
          torch::fft::rfft(tensor_video_padded, /*n=*/std::nullopt, /*dim=*/i)
              .narrow(i, 0, t_cutoff);
    }

    if (true) {
      int64_t constexpr i = 2;

      tensor_video_padded =
          torch::fft::fftshift(
              torch::fft::fft(tensor_video_padded, std::nullopt, /*dim=*/i),
              {i})
              .narrow(i, position_start, len_truncated);
    }

    if (true) {
      int64_t constexpr i = 1;

      tensor_video_padded =
          torch::fft::fftshift(
              torch::fft::fft(tensor_video_padded, std::nullopt, /*dim=*/i),
              {i})
              .narrow(i, position_start, len_truncated);
    }

    if (true) {
      int64_t constexpr i = 0;

      tensor_video_padded = torch::fft::fftshift(
          torch::fft::fft(tensor_video_padded, std::nullopt, /*dim=*/i), {i});
    }

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

    locker.r();

    std::memcpy(dest, compressed_tensor_video_fft.data_ptr(),
                compressed_tensor_video_fft.nbytes());

    return 0;

  } catch (const std::exception &e) {
    printf("Error: %s\n", e.what());
    return -1; // Error
  }
}
}
