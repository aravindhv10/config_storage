#!/usr/bin/env python3
import os

try:
    __file__
except:
    basepath = "."
else:
    basepath = os.path.abspath(os.path.dirname(__file__) + "/")

import sys

sys.path.append(os.path.dirname(basepath))

from common_utils import *
from dataset_dataloader import *
from get_file_list import *
from transformers import ViTForImageClassification


class infer_slave:
    def __init__(self):
        self.MODEL_NAME = "motheecreator/vit-Facial-Expression-Recognition"
        self.model = ViTForImageClassification.from_pretrained(self.MODEL_NAME)

        (
            self.device,
            self.dtype,
        ) = get_good_device_and_dtype()

    def __call__(
        self,
        image,
    ):
        with torch.no_grad():
            y = self.model(image)

        return y


class inference_wrapper:
    def __init__(self):
        self.slave = infer_slave()

    def __call__(
        self,
        path_dir_prefix_input,
        do_unlink=True,
    ):
        loader = get_data_loader(
            path_dir_input=path_dir_prefix_input,
            batch_size=1,
            do_unlink=do_unlink,
        )

        for i in loader:
            (
                path,
                x,
            ) = i
            y = slave(x)
            open(path[: path.rfind(".")] + ".txt", "w").write(str(y))
