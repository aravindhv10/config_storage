#ifndef _HEADER_GUARD_src_main_hpp
#define _HEADER_GUARD_src_main_hpp

#include "./export.hpp"

#include <fcntl.h>
#include <semaphore.h>
#include <sys/stat.h>

#include <iostream>
#include <vector>

#include <opencv2/core/mat.hpp>
#include <opencv2/imgcodecs.hpp>
#include <opencv2/opencv.hpp>

#include <ATen/ops/sum.h>
#include <c10/core/TensorOptions.h>
#include <torch/csrc/inductor/aoti_package/model_package_loader.h>
#include <torch/fft.h>
#include <torch/torch.h>

#ifdef TORCH_HAS_CUDA
    #include <c10/cuda/CUDACachingAllocator.h>
#endif

#endif
