#!/usr/bin/env python3


from albumentations.pytorch import ToTensorV2
import albumentations as A
import cv2
import fcntl
import numpy as np
import torch


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


class image_reader:
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
                ToTensorV2(),
            ]
        )

    def read_image(
        self,
        path_file_image_input,
    ):
        image = read_image(path_file_image_input=path_file_image_input)
        transformed_image = self.transform(image=image)["image"]
        return transformed_image

    def __call__(
        self,
        path_file_image_input,
    ):
        return self.read_image(path_file_image_input)
