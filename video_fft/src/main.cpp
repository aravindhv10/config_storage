#include "./main.hpp"

using float32_t = float;
using float64_t = double;

template <typename T> inline auto get_tensor_dtype() {
  return torch::kBFloat16;
}

template <> inline auto get_tensor_dtype<uint8_t>() {
  return torch::kUInt8;
}

template <> inline auto get_tensor_dtype<uint16_t>() {
  return torch::kUInt16;
}

template <> inline auto get_tensor_dtype<uint32_t>() {
  return torch::kUInt32;
}

template <> inline auto get_tensor_dtype<uint64_t>() {
  return torch::kInt64;
}

template <> inline auto get_tensor_dtype<int8_t>() {
  return torch::kInt8;
}

template <> inline auto get_tensor_dtype<int16_t>() {
  return torch::kInt16;
}

template <> inline auto get_tensor_dtype<int32_t>() {
  return torch::kInt32;
}

template <> inline auto get_tensor_dtype<int64_t>() {
  return torch::kInt64;
}

template <> inline auto get_tensor_dtype<float32_t>() {
  return torch::kFloat32;
}

template <> inline auto get_tensor_dtype<float64_t>() {
  return torch::kFloat64;
}

inline std::string get_model_path() {
  printf("called get_model_path()\n");
  return std::string("/model.pt2");
}

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

class infer_slave {
private:
  c10::InferenceMode mode;
  torch::inductor::AOTIModelPackageLoader loader;
  torch::TensorOptions options_compute;
  torch::TensorOptions options_host_input;
  torch::TensorOptions options_host_output;
  torch::Tensor input_tensor;
  std::vector<torch::Tensor> inputs;
  std::vector<torch::Tensor> outputs;
  torch::Tensor out_tensor;
  std::size_t bytes_to_copy;

public:
  inline void operator()(arg_input *in, unsigned int const batch_size,
                         arg_output *out) {
    torch::Tensor cpu_tensor = torch::from_blob(
        static_cast<void *>(in), {batch_size, SIZE_Y, SIZE_X, SIZE_C},
        options_host_input);
    inputs[0] = cpu_tensor.to(options_compute);
    outputs = loader.run(inputs);
    out_tensor = outputs[0].contiguous().cpu().to(options_host_output);
    bytes_to_copy = batch_size * SIZE_O * sizeof(outtype);
    std::memcpy(out, out_tensor.data_ptr<outtype>(), bytes_to_copy);
  }

  infer_slave()
      : loader(get_model_path()), options_compute(get_good_device_and_dtype()),
        options_host_input(get_host_input_device_and_dtype()),
        options_host_output(get_host_output_device_and_dtype()) {
    printf("Started actual constructor\n");
    inputs.resize(1);
    printf("Done constructing...\n");
  }

  ~infer_slave() {}
};

infer_slave slave;

extern "C" {

void mylibtorchinfer(arg_input *in, unsigned int const batch_size,
                     arg_output *out) {

  slave(in, batch_size, out);
}

bool decode_image_data(unsigned char *binary_data, int data_size,
                       arg_input *dst_struct) {

  /*inline*/ cv::Mat ret =
      process_image_data(/*unsigned char *binary_data =*/binary_data,
                         /*int data_size =*/data_size);

  /*inline*/ bool res = convertMatToStruct(
      /*const cv::Mat& src_mat =*/ret, /*arg_input& dst_struct =*/*dst_struct);

  return res;
}
}

void do_fft_compress(void * blob, int size_t, int size_y, int size_x, int size_c , void * dest){
  
}
