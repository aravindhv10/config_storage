#!/usr/bin/env python3
import os

try:
    __file__
except:
    basepath = os.getcwd()
else:
    basepath = os.path.abspath(os.path.dirname(__file__))

import sys

sys.path.append(os.path.dirname(basepath))
from common_utils import *


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
