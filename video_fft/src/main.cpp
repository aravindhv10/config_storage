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

inline std::string get_compiled_model_path(unsigned char i) {
  switch (i) {
  case 1:
    return std::string("/root/.cache/model_1.pt2");
  case 2:
    return std::string("/root/.cache/model_2.pt2");
  case 3:
    return std::string("/root/.cache/model_3.pt2");
  case 4:
    return std::string("/root/.cache/model_4.pt2");
  default:
    return std::string("/root/.cache/model_1.pt2");
  }
}

void clear_cuda_cache() {
#ifdef USE_CUDA
  c10::cuda::CUDACachingAllocator::emptyCache();
  printf("Cleaned cuda cache...\n");
#endif
}

#define _MACRO_SELF_ file_mlock
class _MACRO_SELF_ {
private:
  int fd;
  void *addr;
  struct stat st;
  bool initialized;

public:
  _MACRO_SELF_(char const *path_file_input)
      : fd(open(path_file_input, O_RDONLY)), initialized(false) {
    if (fd == -1) {
      printf("Error opening file %s\n", path_file_input);
    } else {
      if (fstat(fd, &st)) {
        printf("fstat failed...\n");
      } else {
        addr = mmap(NULL, st.st_size, PROT_READ, MAP_SHARED, fd, 0);
        if (addr == MAP_FAILED) {
          printf("mmap failed...\n");
        } else {
          if (mlock(addr, st.st_size) == 0) {
            printf("File locked in RAM successfully.\n");
            initialized = true;
          } else {
            printf("mlock failed...\n");
          }
        }
      }
    }
  }

  ~_MACRO_SELF_() {
    if (addr != MAP_FAILED) {
      munmap(addr, st.st_size);
    }
    if (fd != -1) {
      close(fd);
    }

    initialized = false;
  }
};
#undef _MACRO_SELF_

#define _MACRO_SELF_ unnamed_semaphore

class _MACRO_SELF_ {
private:
  sem_t main_sem;

public:
  _MACRO_SELF_(int const num) { sem_init(&main_sem, 0, num); }
  ~_MACRO_SELF_() { sem_destroy(&main_sem); }
  inline void l() { sem_wait(&main_sem); }
  inline void r() { sem_post(&main_sem); }

  static inline _MACRO_SELF_ *NEW(int const num) {
    return new _MACRO_SELF_(/*int const num =*/num);
  }

  static inline void DELETE(_MACRO_SELF_ *in) { delete in; }
};

extern "C" {

void *unnamed_semaphore_new(int const num) {
  return static_cast<void *>(_MACRO_SELF_::NEW(/*int const num =*/num));
}

void unnamed_semaphore_delete(void *in) {
  delete static_cast<_MACRO_SELF_ *>(in);
}

void unnamed_semaphore_l(void *in) { static_cast<_MACRO_SELF_ *>(in)->l(); }

void unnamed_semaphore_r(void *in) { static_cast<_MACRO_SELF_ *>(in)->r(); }
}

#undef _MACRO_SELF_

#define _MACRO_SELF_ named_semaphore
class _MACRO_SELF_ {
private:
  sem_t *main_sem;

public:
  _MACRO_SELF_(char const *name, int const num)
      : main_sem(sem_open(name, O_CREAT, S_IRWXU, num)) {}

  ~_MACRO_SELF_() { sem_close(main_sem); }

  inline void l() { sem_wait(main_sem); }
  inline void r() { sem_post(main_sem); }

  static inline _MACRO_SELF_ *NEW(char const *name, int const num) {
    return new _MACRO_SELF_(/*char const *name =*/name, /*int const num =*/num);
  }

  static inline void DELETE(_MACRO_SELF_ *in) { delete in; }
};

extern "C" {

void *named_semaphore_new(char const *name, int const num) {
  return static_cast<void *>(
      _MACRO_SELF_::NEW(/*char const *name =*/name, /*int const num =*/num));
}

void named_semaphore_delete(void *in) {
  delete static_cast<_MACRO_SELF_ *>(in);
}

void named_semaphore_l(void *in) { static_cast<_MACRO_SELF_ *>(in)->l(); }

void named_semaphore_r(void *in) { static_cast<_MACRO_SELF_ *>(in)->r(); }
}

#undef _MACRO_SELF_

#define _MACRO_SELF_ gpu_locker

class _MACRO_SELF_ {

private:
  named_semaphore gpu_semaphore_named;
  unnamed_semaphore gpu_semaphore;
  bool for_inference_server;

  std::vector<file_mlock> mem_locks;

public:
  _MACRO_SELF_()
      : gpu_semaphore_named("/gpuLock", 2), gpu_semaphore(2),
        for_inference_server(false) {}

  ~_MACRO_SELF_() {}

  inline void configure_for_preprocessing() { for_inference_server = false; }

  inline void configure_for_inference() {
    printf("Configuring for inference\n");
    for_inference_server = true;

    printf("Locking compiled models into memory\n");
    if (mem_locks.size() == 0) {
      mem_locks.reserve(4);

      mem_locks.push_back(
          get_compiled_model_path(/*unsigned char i =*/1).c_str());
      mem_locks.push_back(
          get_compiled_model_path(/*unsigned char i =*/2).c_str());
      mem_locks.push_back(
          get_compiled_model_path(/*unsigned char i =*/3).c_str());
      mem_locks.push_back(
          get_compiled_model_path(/*unsigned char i =*/4).c_str());
    }
  }

  inline void l() {
    if (torch::cuda::is_available()) {
      if (for_inference_server) {
        gpu_semaphore_named.l();
      } else {
        gpu_semaphore.l();
      }
    }
  }
  inline void r() {
    if (torch::cuda::is_available()) {
      if (for_inference_server) {
        clear_cuda_cache();
        gpu_semaphore_named.r();
      } else {
        gpu_semaphore.r();
      }
    }
  }
};

static _MACRO_SELF_ locker;

extern "C" {
void locker_to_inference_mode() { locker.configure_for_inference(); }
void locker_to_preprocessing_mode() { locker.configure_for_preprocessing(); }
}

#undef _MACRO_SELF_

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
    try {
      torch::Tensor cpu_tensor = torch::from_blob(
          blob_source, {static_cast<long>(batch_size), 6, 160, 160, 60},
          options_input);

      std::vector<torch::Tensor> inputs = {cpu_tensor.to(options_compute)};

      std::vector<torch::Tensor> outputs = loader.run(inputs);

      torch::Tensor out_tensor = outputs[0].to(options_output).contiguous();

      std::memcpy(blob_destination, out_tensor.const_data_ptr(), bytes_to_copy);

    } catch (const std::exception &e) {

      std::memset(blob_destination, 0, bytes_to_copy);

      printf("Error: %s\n", e.what());
    }
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

    c10::InferenceMode mode;

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

    printf("Acquiring lock\n");
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
    printf("Released lock\n");

    std::memcpy(dest, compressed_tensor_video_fft.data_ptr(),
                compressed_tensor_video_fft.nbytes());

    return 0;

  } catch (const std::exception &e) {
    std::memset(dest, 0, 6 * 160 * 160 * 60 * 4);
    printf("Error: %s\n", e.what());
    return -1; // Error
  }
}
}
