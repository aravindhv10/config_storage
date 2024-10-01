#!/usr/bin/python3
def remove_extension(path_input):
    loc = path_input.rfind('.')
    return path_input[0:loc]

import os


def mkdir_safe(out_path):
    if type(out_path) == str:
        if len(out_path) > 0:
            if not os.path.exists(out_path):
                os.mkdir(out_path)

import subprocess


def download_file_with_aria(path_file, url):
    path_file = os.path.realpath(path_file)
    DIR = os.path.dirname(path_file)
    FILE = os.path.basename(path_file)
    subprocess.run(['mkdir', '-pv', '--', DIR])
    os.chdir(DIR)
    subprocess.run(['aria2c', '-c', '-x16', '-j16', url, '--out', FILE])

import os


def is_file_image(path_input):

    if not os.path.isdir(path_input):

        path_input = path_input.lower()

        if path_input.endswith('.png') or path_input.endswith(
                '.jpg') or path_input.endswith('.jpeg'):

            return True

    return False

import cv2


def do_resize_image_good(inpath, outpath, outres):

    img = cv2.imread(inpath, cv2.IMREAD_COLOR)
    img = img[:, :, 0:3]

    if img.shape[0] < img.shape[1]:

        size_y = outres
        frac = outres / size_y
        size_x = int(img.shape[1] * frac)

    else:

        size_x = outres
        frac = outres / size_x
        size_y = int(img.shape[0] * frac)

    if frac > 1:
        inter = cv2.INTER_CUBIC
    elif frac < 1:
        inter = cv2.INTER_AREA

    img = cv2.resize(img, (size_x, size_y), inter)

    cv2.imwrite(outpath, img)


def do_resize_mask_good(inpath, outpath, outres):

    img = cv2.imread(inpath, cv2.IMREAD_COLOR)
    img = img[:, :, 0:3]

    if img.shape[0] < img.shape[1]:

        size_y = outres
        frac = outres / size_y
        size_x = int(img.shape[1] * frac)

    else:

        size_x = outres
        frac = outres / size_x
        size_y = int(img.shape[0] * frac)

    inter = cv2.INTER_NEAREST_EXACT

    img = cv2.resize(img, (size_x, size_y), inter)

    cv2.imwrite(outpath, img)

import cv2


def load_image_cv2(path_input_image):
    img = cv2.imread(path_input_image, cv2.IMREAD_COLOR)
    img = img[:, :, 0:3]
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    return img


def save_image_cv2(image_input, path_image_output):
    image_input = cv2.cvtColor(image_input[:, :, 0:3], cv2.COLOR_RGB2BGR)
    cv2.imwrite(path_image_output, image_input)

import torch
import gc


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

    return device, dtype


def flush_cuda():
    if torch.cuda.is_available():
        torch.cuda.empty_cache()
    gc.collect()
