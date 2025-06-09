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

from albumentations.pytorch import ToTensorV2
from torch.utils.data import DataLoader
from torch.utils.data import Dataset
import albumentations as A
import cv2
import fcntl
import numpy as np
import torch


def mkdir_safe(out_path):
    if type(out_path) == str:
        if len(out_path) > 0:
            os.makedirs(out_path, exist_ok=True)


def is_path_file_video(path_input):
    if (not os.path.exists(path_input)) or (os.path.isdir(path_input)):
        return False
    else:
        path_input = path_input.lower()
        return path_input.endswith(".mp4")


def is_path_file_image(path_input):
    if (not os.path.exists(path_input)) or (os.path.isdir(path_input)):
        return False
    else:
        path_input = path_input.lower()
        return (
            path_input.endswith(".jpg")
            or path_input.endswith(".jpeg")
            or path_input.endswith(".png")
            or path_input.endswith(".bmp")
        )


def get_list_path_file_video_input(path_dir_input="/data/input"):
    list_path_file_input = []

    for (
        root,
        dirs,
        files,
    ) in os.walk(path_dir_input):
        list_path_file_input += filter(
            is_path_file_video,
            [root + "/" + i for i in files],
        )

    return list_path_file_input


def get_list_path_file_image_input(path_dir_input="/data/input"):
    list_path_file_input = []

    for (
        root,
        dirs,
        files,
    ) in os.walk(path_dir_input):
        list_path_file_input += filter(
            is_path_file_image,
            [root + "/" + i for i in files],
        )

    return list_path_file_input


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


def get_dataset(
    path_dir_input="/data/input",
    repeat_factor=1,
    force_length=None,
):
    slave = CustomImageDataset(
        list_data_input=get_list_path_file_image_input(path_dir_input=path_dir_input),
        repeat_factor=repeat_factor,
        force_length=force_length,
    )

    return slave


def get_data_loader(
    path_dir_input="/data/input",
    batch_size=16,
    train_mode=False,
    repeat_factor=1,
    force_length=None,
):
    dataset = get_dataset(
        path_dir_input=path_dir_input,
        repeat_factor=repeat_factor,
        force_length=force_length,
    )

    return DataLoader(
        dataset,
        batch_size=batch_size,
        shuffle=train_mode,
        num_workers=8,
    )


class class_read_image_processed:
    def __init__(self):
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
        repeat_factor=1,
        force_length=None,
    ):
        self.repeat_factor = repeat_factor
        self.list_data_input = list_data_input
        self.actual_length = len(self.list_data_input)
        self.force_length = force_length
        self.main_read_image_processed = class_read_image_processed()

    def __len__(self):
        if self.force_length is not None:
            return self.force_length
        else:
            return self.actual_length * self.repeat_factor

    def __getitem__(
        self,
        i,
    ):
        i = i % self.actual_length

        path_file_image = self.list_data_input[i]

        tensor = self.main_read_image_processed(path_file_image)

        return (
            path_file_image,
            tensor,
        )
