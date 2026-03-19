#ifndef _HEADER_GUARD_src_main_hpp
#define _HEADER_GUARD_src_main_hpp

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

#include "./export.hpp"

#endif
