#!/usr/bin/env python3
import os

try:
    __file__
except:
    basepath = "."
else:
    basepath = os.path.abspath(os.path.dirname(__file__) + "/")

import sys

sys.path.append(basepath)
import torch


def mkdir_safe(out_path):
    if type(out_path) == str:
        if len(out_path) > 0:
            os.makedirs(out_path, exist_ok=True)


def rmdir_safe(out_path):
    if type(out_path) == str:
        if len(out_path) > 0:
            if os.path.exists(out_path):
                os.rmdir(out_path)


def unlink_safe(out_path):
    if type(out_path) == str:
        if len(out_path) > 0:
            if os.path.exists(out_path):
                os.unlink(out_path)


def remove_extension(path_input):
    loc = path_input.rfind(".")
    return path_input[0:loc]


def get_good_device_and_dtype():
    device = "cpu"
    dtype = torch.float32

    if torch.cuda.is_available():
        torch.backends.cudnn.benchmark = True
        device = "cuda:0"
        dtype = torch.float16
        if torch.cuda.get_device_capability()[0] >= 8:
            dtype = torch.bfloat16

    device = torch.device(device)

    return (
        device,
        dtype,
    )
