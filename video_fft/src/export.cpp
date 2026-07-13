using float32_t = float;
using float64_t = double;

using intype = unsigned char;
using outtype = float;

void *unnamed_semaphore_new(int const num);
void unnamed_semaphore_delete(void *in);
void unnamed_semaphore_l(void *in);
void unnamed_semaphore_r(void *in);

void *named_semaphore_new(char const *name, int const num);
void named_semaphore_delete(void *in);
void named_semaphore_l(void *in);
void named_semaphore_r(void *in);

void locker_to_inference_mode();
void locker_to_preprocessing_mode();

int do_fft_compress_efficient(void *const blob, uint16_t const len_t,
                              uint16_t const len_y, uint16_t const len_x,
                              uint8_t const len_c, float32_t const fps,
                              float32_t const freq_limit, void *const dest,
                              bool use_gpu);

void clear_cuda_cache();

void *new_infer_slave_image_cv_usability(unsigned char batch_size);
void delete_infer_slave_image_cv_usability(void *in);
int run_infer_slave_image_cv_usability(void *in, void *blob_source, void *blob_destination);

void *new_infer_slave_image(unsigned char batch_size);
void delete_infer_slave_image(void *in);
int run_infer_slave_image(void *in, void *blob_source, void *blob_destination);

void *new_infer_slave(unsigned char batch_size);
void delete_infer_slave(void *in);
int run_infer_slave(void *in, void *blob_source, void *blob_destination);
