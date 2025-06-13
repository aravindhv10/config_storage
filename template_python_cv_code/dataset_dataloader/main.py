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

from albumentations.pytorch import ToTensorV2
from common_utils import *
from get_file_list import *
from torch.utils.data import DataLoader
from torch.utils.data import Dataset
from transformers import ViTForImageClassification
import albumentations as A
import cv2
import fcntl
import numpy as np
import torch


def obtain_lock(infd):
    fcntl.flock(
        infd.fileno(),
        fcntl.LOCK_SH,
    )


def release_lock(infd):
    fcntl.flock(
        infd.fileno(),
        fcntl.LOCK_UN,
    )


def read_image(path_file_image_input):
    tmpfd = open(
        path_file_image_input,
        "rb",
    )

    obtain_lock(infd=tmpfd)

    image = np.frombuffer(
        tmpfd.read(),
        np.uint8,
    )

    release_lock(infd=tmpfd)
    tmpfd.close()

    image = cv2.imdecode(
        image,
        cv2.IMREAD_COLOR,
    )

    image = cv2.cvtColor(
        src=image,
        code=cv2.COLOR_BGR2RGB,
    )

    return image


def read_image_and_unlink(path_file_image_input):
    res = read_image(path_file_image_input=path_file_image_input)
    os.unlink(path_file_image_input)
    return res


def get_dataset(path_dir_input="/data/input"):
    slave = CustomImageDataset(
        list_data_input=get_list_path_file_image_input(path_dir_input=path_dir_input)
    )

    return slave


def get_data_loader(
    path_dir_input="/data/input",
    batch_size=16,
    num_workers=4,
):
    dataset = get_dataset(path_dir_input=path_dir_input)

    return DataLoader(
        dataset,
        batch_size=batch_size,
        shuffle=False,
        num_workers=num_workers,
    )


class class_read_image_processed:
    def __init__(
        self,
        do_unlink=True,
    ):
        self.do_unlink = do_unlink

        self.imagenet_mean = [
            0.485,
            0.456,
            0.406,
        ]

        self.imagenet_std = [
            0.229,
            0.224,
            0.225,
        ]

        self.transform = A.Compose(
            [
                A.Normalize(
                    mean=self.imagenet_mean,
                    std=self.imagenet_std,
                ),
                A.Resize(
                    height=224,
                    width=224,
                    interpolation=cv2.INTER_AREA,
                    mask_interpolation=cv2.INTER_NEAREST_EXACT,
                ),
                ToTensorV2(),
            ]
        )

        (
            self.device,
            self.dtype,
        ) = get_good_device_and_dtype()

    def __call__(
        self,
        path_file_image_input,
    ):
        if self.do_unlink:
            image = read_image_and_unlink(path_file_image_input=path_file_image_input)
        else:
            image = read_image(path_file_image_input=path_file_image_input)

        image = self.transform(image=image)["image"].to(
            device=self.device,
            dtype=self.dtype,
        )

        return image


class CustomImageDataset(Dataset):
    def __init__(
        self,
        list_data_input,
    ):
        self.list_data_input = list_data_input
        self.actual_length = len(self.list_data_input)
        self.main_read_image_processed = class_read_image_processed()

    def __len__(self):
        return self.actual_length

    def __getitem__(
        self,
        i,
    ):
        path_file_image = self.list_data_input[i]
        tensor = self.main_read_image_processed(path_file_image)

        return (
            path_file_image,
            tensor,
        )


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
    ):
        loader = get_data_loader(
            path_dir_input=path_dir_prefix_input,
            batch_size=1,
        )

        for i in loader:
            (
                path,
                x,
            ) = i
            y = slave(x)
            open(path[: path.rfind(".")] + ".txt", "w").write(str(y))
            os.unlink(path)
