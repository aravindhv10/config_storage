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
INPUT_IMAGE_RESOLUTION = 448
from datetime import datetime
from safetensors.torch import load_file
from safetensors.torch import save_file
import albumentations as A
import cv2
import einops
import fcntl
import hashlib
import inotify_simple
import json
import numpy as np
import shutil
import subprocess
import torch


def create_empty_file(path_file_input):
    open(path_file_input, "w").close()


def ln_safe(
    path_file_source,
    path_file_dest,
):
    if os.path.exists(path_file_source) and (not os.path.exists(path_file_dest)):
        os.link(
            src=path_file_source,
            dst=path_file_dest,
        )


def mkdir_safe(out_path):
    if type(out_path) == str:
        if len(out_path) > 0:
            os.makedirs(out_path, exist_ok=True)


def move_safe(
    path_file_input,
    path_file_output,
):
    if os.path.exists(path_file_input):
        os.replace(
            src=path_file_input,
            dst=path_file_output,
        )
        return True
    else:
        return False


def safe_remove(path_dir_input):
    if os.path.exists(path_dir_input):
        shutil.rmtree(path=path_dir_input)


def cp_tree_recursive(
    path_dir_source,
    path_dir_dest,
):
    if os.path.exists(path_dir_source) and os.path.isdir(path_dir_source):
        path_dir_parent = os.path.dirname(path_dir_dest)
        safe_remove(path_dir_input=path_dir_dest)
        mkdir_safe(out_path=path_dir_parent)
        os.system("cp -alpf -- '" + path_dir_source + "' '" + path_dir_dest + "'")
    else:
        print("Failed copy, source does not exist: " + path_dir_source)


def safe_recopy(
    path_dir_input,
    path_dir_output,
):
    path_dir_parent = os.path.dirname(path_dir_output)
    safe_remove(path_dir_input=path_dir_output)
    mkdir_safe(out_path=path_dir_parent)
    shutil.copytree(
        src=path_dir_input,
        dst=path_dir_output,
    )


def safe_remove(path_dir_input):
    if os.path.exists(path_dir_input):
        shutil.rmtree(path=path_dir_input)


def safe_recopy(
    path_dir_input,
    path_dir_output,
):
    path_dir_parent = os.path.dirname(path_dir_output)
    safe_remove(path_dir_input=path_dir_output)
    mkdir_safe(out_path=path_dir_parent)
    shutil.copytree(
        src=path_dir_input,
        dst=path_dir_output,
    )


def load_tensor(path_file_tensor_input):
    if not path_file_tensor_input.endswith(".safetensors"):
        path_file_tensor_input += ".safetensors"
    mydict = load_file(
        filename=path_file_tensor_input,
    )
    return mydict["main_tensor"]


def save_tensor(tensor_input, path_file_tensor_input):
    if not path_file_tensor_input.endswith(".safetensors"):
        path_file_tensor_input += ".safetensors"
    mydict = {"main_tensor": tensor_input.contiguous()}
    save_file(
        tensors=mydict,
        filename=path_file_tensor_input,
    )


def get_hasher():
    return hashlib.sha3_256()


def hash_file(path_file_input):
    main_hasher = get_hasher()
    with open(
        path_file_input,
        "rb",
    ) as f:
        main_hasher.update(f.read())
    return main_hasher.hexdigest()


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


def obtain_lock_exclusive_write(infd):
    fcntl.flock(
        infd.fileno(),
        fcntl.LOCK_EX,
    )


def release_lock_exclusive_write(infd):
    release_lock(infd)


def read_file_locked(path_file_image_input):
    tmpfd = open(
        path_file_image_input,
        "rb",
    )
    obtain_lock(infd=tmpfd)
    content = tmpfd.read()
    release_lock(infd=tmpfd)
    tmpfd.close()
    return content


def decode_image(
    content,
    path_file_image_input=None,
):
    image = np.frombuffer(
        content,
        np.uint8,
    )
    try:
        image = cv2.imdecode(
            image,
            cv2.IMREAD_COLOR,
        )
        image = cv2.cvtColor(
            src=image,
            code=cv2.COLOR_BGR2RGB,
        )
    except:
        print("Failed reading image " + path_file_image_input)
        image = np.zeros(
            (
                INPUT_IMAGE_RESOLUTION,
                INPUT_IMAGE_RESOLUTION,
                3,
            ),
            dtype=np.uint8,
        )
    return image


def read_image(path_file_image_input):
    return decode_image(
        content=read_file_locked(path_file_image_input=path_file_image_input),
        path_file_image_input=path_file_image_input,
    )


def read_image_contents(path_file_image_input):
    content = read_file_locked(path_file_image_input=path_file_image_input)
    return (
        decode_image(
            content=content,
            path_file_image_input=path_file_image_input,
        ),
        content,
    )


def path_file_image_2_torch(path_file_image_input):
    image = read_image(path_file_image_input=path_file_image_input)
    os.unlink(path=path_file_image_input)
    image = torch.from_numpy(image)
    return image


def S1_forward_read(path_file_image):
    image = cv2.imread(path_file_image, cv2.IMREAD_COLOR)
    image = torch.from_numpy(image)
    return image


def S1_inverse_write(path_file_image, image):
    image = image.numpy()
    ret = cv2.imwrite(path_file_image, image)
    return ret


def S2_forward_rescale(image):
    image = image.to(dtype=torch.float64)
    image /= 255.0
    return image


def S2_inverse_rescale(image):
    image *= 255.0
    image = image.to(dtype=torch.uint8)
    return image


def S3_forward_remap(image):
    image = einops.rearrange(image, "H W C -> C H W")
    return image


def S3_inverse_remap(image):
    image = einops.rearrange(image, "C H W -> H W C")
    return image


def S4_forward_fft(image, factor):
    s = (image.shape[1] // factor, image.shape[2] // factor)
    image = torch.fft.fft2(image, s=s)
    return image


def S4_inverse_fft(image, factor):
    s = (image.shape[1] * factor, image.shape[2] * factor)
    image = torch.fft.ifft2(image, s)
    # image = torch.abs(image)
    image = image.real
    return image


def S5_forward_fft_truncate(image, FACTOR):
    image = image[
        0 : image.shape[0], 0 : image.shape[1] // FACTOR, 0 : image.shape[2] // FACTOR
    ]
    return image


def S5_inverse_fft_truncate(image, FACTOR):
    tmp = torch.zeros(
        (image.shape[0], image.shape[1] * FACTOR, image.shape[2] * FACTOR),
        dtype=image.dtype,
    )
    tmp[0 : image.shape[0], 0 : image.shape[1], 0 : image.shape[2]] = image
    return tmp


def S6_SVD_Compress_Forward(image, infactor):
    (u, s, vH) = torch.linalg.svd(A=image, full_matrices=False)
    s = s.to(dtype=vH.dtype)
    insize = u.shape[2] // infactor
    u = u[:, :, :insize]
    s = s[:, :insize]
    vH = vH[:, :insize, :]
    return (u, s, vH)


def S6_SVD_Compress_Inverse(u, s, vH):
    return torch.matmul(u, torch.matmul(torch.diag(s), vH))


def do_process(u, s, vH):
    u = einops.rearrange(u, "C J D -> J C D")
    s = einops.rearrange(s, "C (J D) -> J C D", J=1)
    vH = einops.rearrange(vH, "C D J -> J C D")
    res = torch.cat((s, u, vH))
    return res


def do_process_complex(u, s, vH):
    res = do_process(u, s, vH)
    res = einops.rearrange(res, "J C D -> J (C D)")
    return res


def do_process_real(u, s, vH):
    res = do_process(u, s, vH)
    res = einops.rearrange(res, "J C D -> C J D")
    out = torch.zeros(
        (
            res.shape[0] * 2,
            res.shape[1],
            res.shape[2],
        ),
        dtype=torch.float32,
    )
    out[0 : res.shape[0], :, :] = torch.abs(res)
    out[res.shape[0] : res.shape[0] * 2, :, :] = torch.angle(res)
    out = einops.rearrange(out, "C J D -> J (C D)")
    return out


def read_image_complex_and_compress(
    path_file_image_input,
    FACTOR_FFT=8,
    FACTOR_SVD=16,
):
    image = read_image(path_file_image_input)
    image = torch.from_numpy(image).to(DEVICE)
    image = S2_forward_rescale(image)
    image = S3_forward_remap(image)
    image = S4_forward_fft(image, FACTOR_FFT)
    # tmp1 = torch.clone(image)
    # image = S5_forward_fft_truncate(image, FACTOR_FFT)
    (u, s, vH) = S6_SVD_Compress_Forward(image, FACTOR_SVD)
    # merged = do_process(u, s, vH)
    merged = do_process_complex(u, s, vH)
    return merged


def image_2_torch_complex_compressed(
    path_file_image_input,
    FACTOR_FFT=8,
    FACTOR_SVD=16,
):
    image = path_file_image_2_torch(path_file_image_input=path_file_image_input)
    image = image.to(dtype=torch.float32, device=DEVICE) / 255.0
    image = einops.rearrange(image, "H W C -> C H W")
    image = S4_forward_fft(image, FACTOR_FFT)
    (u, s, vH) = S6_SVD_Compress_Forward(image, FACTOR_SVD)
    merged = do_process_complex(u, s, vH)
    return merged


def image_2_torch_complex_fft_compressed(
    path_file_image_input,
    FACTOR_FFT=8,
):
    image = path_file_image_2_torch(path_file_image_input=path_file_image_input)
    image = image.to(dtype=torch.float32, device=DEVICE) / 255.0
    image = einops.rearrange(image, "H W C -> C H W")
    image = S4_forward_fft(image, FACTOR_FFT)
    return image


def video_2_image(
    path_file_video_input,
    fps=8,
    force=False,
):
    loc = path_file_video_input.rfind(".")
    if loc >= 0:
        path_dir_output = path_file_video_input[:loc] + ".dir"
    else:
        path_dir_output = path_file_video_input + ".dir"
    if os.path.isdir(path_dir_output):
        if force:
            safe_remove(path_dir_input=path_dir_output)
        else:
            return path_dir_output
    mkdir_safe(path_dir_output)
    subprocess.run(
        [
            "ffmpeg",
            "-i",
            path_file_video_input,
            "-r",
            str(fps),
            "-vf",
            "scale=1280:720",
            path_dir_output + "/out-%6d.bmp",
        ]
    )
    return path_dir_output


def video_2_torch(path_file_video_input):
    path_dir_out = video_2_image(
        path_file_video_input=path_file_video_input,
        fps=8,
    )
    list_path_file_image_under_dir = get_list_path_file_image_under_dir(
        path_dir_input=path_dir_out
    )
    video = torch.cat(
        list(
            path_file_image_2_torch(path_file_image_input=i).unsqueeze(0)
            for i in get_list_path_file_image_under_dir(path_dir_input=path_dir_out)
        )
    )
    os.rmdir(path_dir_out)
    return video


def get_dataloader_video_2_torch(
    path_file_video_input,
    fps=8,
    batch_size=32,
    num_workers=4,
):
    dataset = dataset_video_2_torch(
        path_file_video_input=path_file_video_input,
        fps=fps,
    )
    dataloader = torch.utils.data.DataLoader(
        dataset,
        batch_size=batch_size,
        shuffle=False,
        num_workers=num_workers,
    )
    return dataloader


def video_2_fft_compressed_tensor(
    path_file_video_input,
    fps=8,
    batch_size=512,
    factor=8,
    freq_limit=3.0,
    num_workers=4,
):
    def do_space_fft(x):
        x = x.to(device=DEVICE, dtype=torch.float32)
        x = einops.rearrange(x, "B Y X C -> B C Y X")
        s = (x.shape[2] // factor, x.shape[3] // factor)
        x = torch.fft.fft2(x, s=s)
        return x

    x = torch.cat(
        list(
            do_space_fft(x)
            for x in get_dataloader_video_2_torch(
                path_file_video_input=path_file_video_input,
                fps=fps,
                batch_size=batch_size,
                num_workers=num_workers,
            )
        )
    )
    x = einops.rearrange(x, "T C Y X -> C Y X T")
    freq = torch.fft.fftfreq(
        n=x.shape[-1],
        d=1.0 / fps,
    )
    valid = (freq > 0) & (freq < freq_limit)
    x = torch.fft.fft2(x, s=[valid[valid].shape[0]], dim=-1)
    y = torch.zeros(
        (
            2,
            x.shape[0],
            x.shape[1],
            x.shape[2],
            x.shape[3],
        ),
        dtype=torch.float32,
    )
    y[0] = torch.abs(x)
    y[1] = torch.angle(x)
    del x
    y = einops.rearrange(y, "R C Y X T -> (R C) T Y X")
    return y


def video_2_fft_compressed_safetensor(
    path_file_video_input,
    fps=8,
    batch_size=512,
    factor=8,
    freq_limit=3.0,
    num_workers=4,
):
    loc = path_file_video_input.rfind(".")
    if loc >= 0:
        path_file_safetensors_output = path_file_video_input[0:loc] + ".safetensors"
    else:
        path_file_safetensors_output = path_file_video_input + ".safetensors"
    if not os.path.exists(path_file_safetensors_output):
        if loc >= 0:
            path_dir_tmp = path_file_video_input[0:loc] + ".dir"
        else:
            path_dir_tmp = path_file_video_input + ".dir"
        tensor = video_2_fft_compressed_tensor(
            path_file_video_input,
            fps=fps,
            batch_size=batch_size,
            factor=factor,
            freq_limit=freq_limit,
            num_workers=num_workers,
        )
        save_tensor(
            tensor_input=tensor,
            path_file_tensor_input=path_file_safetensors_output,
        )
        os.rmdir(path_dir_tmp)
    return path_file_safetensors_output


def video_2_torch_compressed_complex(
    path_file_video_input,
    FACTOR_FFT=8,
    FACTOR_SVD=16,
    fps=8,
):
    path_dir_out = video_2_image(
        path_file_video_input=path_file_video_input,
        fps=fps,
    )
    list_path_file_image_under_dir = list(
        get_list_path_file_image_under_dir(path_dir_input=path_dir_out)
    )
    list_path_file_image_under_dir.sort()
    video = torch.cat(
        list(
            image_2_torch_complex_compressed(i).unsqueeze(0)
            for i in list_path_file_image_under_dir
        )
    )
    os.rmdir(path_dir_out)
    return video


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


def is_path_file(path_input):
    if os.path.exists(path_input):
        if os.path.isdir(path_input):
            return False
        else:
            return True
    else:
        return False


def is_path_file_json(path_input):
    if is_path_file(path_input=path_input):
        path_input = path_input.lower()
        return path_input.endswith(".json")
    else:
        return False


def is_path_file_image(path_input):
    if is_path_file(path_input=path_input):
        path_input = path_input.lower()
        return (
            path_input.endswith(".jpg")
            or path_input.endswith(".jpeg")
            or path_input.endswith(".png")
            or path_input.endswith(".bmp")
        )
    else:
        return False


def is_path_file_video(path_input):
    if is_path_file(path_input=path_input):
        path_input = path_input.lower()
        return path_input.endswith(".mp4") or path_input.endswith(".avi")
    else:
        return False


def is_path_file_safetensors(path_input):
    if is_path_file(path_input=path_input):
        path_input = path_input.lower()
        return path_input.endswith(".safetensors")
    else:
        return False


def convert_path_in_2_out_tmp(path_file_image_input):
    if is_path_file_image(path_input=path_file_image_input):
        loc = path_file_image_input.rfind(".")
        return path_file_image_input[0:loc] + ".tmp"
    else:
        return path_file_image_input + ".tmp"


def convert_path_in_2_out_json(path_file_image_input):
    if is_path_file_image(path_input=path_file_image_input):
        loc = path_file_image_input.rfind(".")
        return path_file_image_input[0:loc] + ".json"
    else:
        return path_file_image_input + ".json"


def convert_path_in_2_out(path_file_image_input):
    if is_path_file_image(path_input=path_file_image_input):
        loc = path_file_image_input.rfind(".")
        return path_file_image_input[0:loc] + ".txt"
    else:
        return path_file_image_input + ".txt"


def is_path_file_uninferred_image(path_input):
    if is_path_file_image(path_input=path_input):
        path_file_json = convert_path_in_2_out_json(path_file_image_input=path_input)
        if is_path_file_json(path_input=path_file_json):
            return False
        else:
            return True
    else:
        return False


def is_path_file_uninferred_image_and_clean(path_input):
    val = is_path_file_uninferred_image(path_input)
    if not val:
        os.unlink(path_input)
    return val


def get_list_path_file_under_dir(path_dir_input):
    list_path_file_input = []
    for (
        root,
        dirs,
        files,
    ) in os.walk(path_dir_input):
        list_path_file_input += [root + "/" + i for i in files]
    return list_path_file_input


def get_list_path_file_image_under_dir(path_dir_input):
    return filter(
        is_path_file_image,
        get_list_path_file_under_dir(path_dir_input),
    )


def get_list_path_file_safetensors_under_dir(path_dir_input):
    return filter(
        is_path_file_safetensors,
        get_list_path_file_under_dir(path_dir_input),
    )


def get_list_path_file_video_under_dir(path_dir_input):
    return filter(
        is_path_file_video,
        get_list_path_file_under_dir(path_dir_input),
    )


def get_list_path_file_uninferred_image_under_dir(path_dir_input):
    return filter(
        is_path_file_uninferred_image,
        get_list_path_file_image_under_dir(path_dir_input),
    )


def get_list_path_file_uninferred_image_under_dir_and_cleanup(path_dir_input):
    return filter(
        is_path_file_uninferred_image_and_clean,
        get_list_path_file_image_under_dir(path_dir_input),
    )


def write_classes_json_if_not_exist(path_dir_prefix_input):
    if os.path.isdir(path_dir_prefix_input):
        path_dir_prefix_input = os.path.realpath(path_dir_prefix_input)
        path_file_json_classes = path_dir_prefix_input + "/labels.json"
        if not os.path.exists(path_file_json_classes):
            list_classes = [
                i
                for i in os.listdir(path_dir_prefix_input)
                if os.path.isdir(path_dir_prefix_input + "/" + i)
            ]
            list_classes.sort()
            out_dict = {name: i for i, name in enumerate(list_classes)}
            print(list_classes)
            with open(
                path_file_json_classes,
                "w",
                encoding="utf-8",
            ) as f:
                json.dump(
                    out_dict,
                    f,
                )
        return path_file_json_classes
    else:
        return None


def write_classes_txt_if_not_exist(path_dir_prefix_input):
    if os.path.isdir(path_dir_prefix_input):
        path_dir_prefix_input = os.path.realpath(path_dir_prefix_input)
        path_file_txt_classes = path_dir_prefix_input + "/classes.txt"
        if not os.path.exists(path_file_txt_classes):
            list_classes = [
                i
                for i in os.listdir(path_dir_prefix_input)
                if os.path.isdir(path_dir_prefix_input + "/" + i)
            ]
            list_classes.sort()
            print(list_classes)
            with open(
                path_file_txt_classes,
                "w",
                encoding="utf-8",
            ) as f:
                for i in list_classes:
                    f.write(i)
                    f.write("\n")
        return path_file_txt_classes
    else:
        return None


def get_list_path_safetensors_with_labels_under_dir(path_dir_prefix_input):
    if os.path.isdir(path_dir_prefix_input):
        path_file_json_classes = write_classes_json_if_not_exist(path_dir_prefix_input)
        slave_label = get_file_class_from_json(path_file_json_classes)
        return list(
            slave_label(i)
            for i in get_list_path_file_safetensors_under_dir(
                path_dir_input=os.path.dirname(path_file_json_classes)
            )
        )
    else:
        return []


def get_list_path_image_with_labels_under_dir(path_dir_prefix_input):
    if os.path.isdir(path_dir_prefix_input):
        path_file_json_classes = write_classes_json_if_not_exist(path_dir_prefix_input)
        slave_label = get_image_class_from_json(path_file_json_classes)
        return list(
            slave_label(i)
            for i in get_list_path_file_image_under_dir(
                path_dir_input=os.path.dirname(path_file_json_classes)
            )
        )
    else:
        return []


def safe_write_dict_to_json(
    indict,
    path_file_tmp,
    path_file_json_output,
):
    with open(
        path_file_tmp,
        "w",
        encoding="utf-8",
    ) as f:
        json.dump(
            indict,
            f,
        )
    move_safe(
        path_file_input=path_file_tmp,
        path_file_output=path_file_json_output,
    )


class dataset_video_2_torch(torch.utils.data.Dataset):
    def __init__(self, path_file_video_input, fps=8):
        self.path_dir_output = video_2_image(
            path_file_video_input,
            fps=fps,
            force=True,
        )
        self.list_path_file_image_under_dir = list(
            get_list_path_file_image_under_dir(path_dir_input=self.path_dir_output)
        )
        self.list_path_file_image_under_dir.sort()

    def __len__(self):
        return len(self.list_path_file_image_under_dir)

    def __getitem__(self, i):
        return path_file_image_2_torch(
            path_file_image_input=self.list_path_file_image_under_dir[i]
        )


class get_file_class_from_json:
    def __init__(
        self,
        path_file_json_class_list,
    ):
        with open(
            path_file_json_class_list,
            "r",
            encoding="utf-8",
        ) as f:
            self.myclasses = json.load(f)
        self.len_path_dir_prefix_base = len(os.path.dirname(path_file_json_class_list))

    def get_list_class_of_file(
        self,
        path_file_input,
    ):
        if is_path_file(path_input=path_file_input) and (
            len(path_file_input) > self.len_path_dir_prefix_base
        ):
            path_file_input = path_file_input[self.len_path_dir_prefix_base :]
            return set(
                [
                    self.myclasses[i]
                    for i in path_file_input.split("/")
                    if i in self.myclasses.keys()
                ]
            )
        else:
            return None

    def get_class_of_file(
        self,
        path_file_input,
    ):
        ret = self.get_list_class_of_file(path_file_input)
        if (ret is None) or (len(ret) < 1):
            return (
                path_file_input,
                None,
            )
        else:
            return (
                path_file_input,
                list(ret)[0],
            )

    def __call__(
        self,
        path_file_input,
    ):
        return self.get_class_of_file(path_file_input=path_file_input)


class get_image_class_from_json:
    def __init__(
        self,
        path_file_json_class_list,
    ):
        with open(path_file_json_class_list, "r", encoding="utf-8") as f:
            self.myclasses = json.load(f)
        self.len_path_dir_prefix_base = len(os.path.dirname(path_file_json_class_list))

    def get_list_class_of_image(
        self,
        path_file_input,
    ):
        if is_path_file_image(path_input=path_file_input) and (
            len(path_file_input) > self.len_path_dir_prefix_base
        ):
            path_file_input = path_file_input[self.len_path_dir_prefix_base :]
            return set(
                [
                    self.myclasses[i]
                    for i in path_file_input.split("/")
                    if i in self.myclasses.keys()
                ]
            )
        else:
            return None

    def get_class_of_image(
        self,
        path_file_input,
    ):
        ret = self.get_list_class_of_image(path_file_input)
        if (ret is None) or (len(ret) < 1):
            return (
                path_file_input,
                None,
            )
        else:
            return (
                path_file_input,
                list(ret)[0],
            )

    def __call__(
        self,
        path_file_input,
    ):
        return self.get_class_of_image(path_file_input=path_file_input)


class save_loader:
    def get_dir_name(self, num):
        if num < 10:
            dir_string = self.path_dir_store + "/00000" + str(num)
        elif 10 <= num and num < 100:
            dir_string = self.path_dir_store + "/0000" + str(num)
        elif 100 <= num and num < 1000:
            dir_string = self.path_dir_store + "/000" + str(num)
        elif 1000 <= num and num < 10000:
            dir_string = self.path_dir_store + "/00" + str(num)
        elif 10000 <= num and num < 100000:
            dir_string = self.path_dir_store + "/0" + str(num)
        elif 100000 <= num and num < 1000000:
            dir_string = self.path_dir_store + "/" + str(num)
        else:
            dir_string = self.path_dir_store + "/too_big"
        return dir_string

    def get_latest(self):
        for i in range(0, 1000000):
            if not os.path.exists(self.get_dir_name(i)):
                return i
        return 1000000

    def __init__(self, path_dir_store):
        self.path_dir_store = path_dir_store
        self.count = self.get_latest()

    def push(
        self,
        model,
        loss,
    ):
        base_dir = self.get_dir_name(self.count)
        mkdir_safe(base_dir)
        out_path = base_dir + "/model.safetensors"
        save_file(model.state_dict(), out_path)
        out_path = base_dir + "/loss.txt"
        open(out_path, "w", encoding="utf-8").write(str(loss))
        self.count += 1

    def pull(self):
        tmp_count = self.count - 1
        if tmp_count >= 0:
            out_path = self.get_dir_name(tmp_count) + "/model.safetensors"
            if os.path.exists(out_path):
                print("loading from ", out_path)
                return load_file(out_path)
            else:
                print("Not able to load any")
                return None
        else:
            print("Not able to load any")
            return None


class running_loss:
    def __init__(self):
        self.n = 0
        self.N = 100000
        self.loss = 0

    def get_run(
        self,
        in_loss,
    ):
        f0 = (self.N - 1) / self.N
        f1 = 1 / self.N
        self.n = (f0 * self.n) + f1
        self.loss = (f0 * self.loss) + (f1 * in_loss)
        return self.loss / self.n

    def __call__(
        self,
        in_loss,
    ):
        return self.get_run(in_loss)


class notify_dataset:
    def __init__(self, path_dir_prefix_input):
        self.path_dir_prefix_input = path_dir_prefix_input
        self.inotify = inotify_simple.INotify()
        self.watch_flags = inotify_simple.flags.CREATE
        self.wd = self.inotify.add_watch(path_dir_prefix_input, self.watch_flags)
        self.main = self.start

    def start(self, timeout=200):
        self.main = self.watch
        looper = set(os.listdir(self.path_dir_prefix_input))
        start_time = datetime.now()
        end_time = datetime.now()
        diff = end_time - start_time
        timediff = (diff.seconds * 1000) + (diff.microseconds / 1000)
        while timediff < timeout:
            for i in self.inotify.read(timeout=timeout):
                looper.add(i.name)
            end_time = datetime.now()
            diff = end_time - start_time
            timediff = (diff.seconds * 1000) + (diff.microseconds / 1000)
        return looper

    def watch(self, timeout=200):
        looper = set(i.name for i in self.inotify.read())
        start_time = datetime.now()
        end_time = datetime.now()
        diff = end_time - start_time
        timediff = (diff.seconds * 1000) + (diff.microseconds / 1000)
        while timediff < timeout:
            for i in self.inotify.read(timeout=timeout):
                looper.add(i.name)
            end_time = datetime.now()
            diff = end_time - start_time
            timediff = (diff.seconds * 1000) + (diff.microseconds / 1000)
        return looper

    def __call__(self, timeout=200):
        return self.main(timeout)


class process_image_for_infer:
    def __init__(
        self,
        image_resolution=448,
    ):
        self.transform = A.Compose(
            [
                # Resize shortest side to TARGET_SIZE, maintaining aspect ratio
                A.SmallestMaxSize(
                    max_size=image_resolution,
                    p=1.0,
                ),
                # Take a random IMAGE_RESOLUTION x IMAGE_RESOLUTION crop
                A.CenterCrop(
                    height=image_resolution,
                    width=image_resolution,
                    p=1.0,
                ),
            ]
        )

    def process_image(
        self,
        x,
    ):
        augmented_data = self.transform(image=x)
        x = augmented_data["image"]
        return x

    def read_and_process_image(
        self,
        path_file_image_input,
    ):
        x = read_image(path_file_image_input=path_file_image_input)
        os.unlink(path=path_file_image_input)
        x = self.process_image(x)
        x = torch.from_numpy(x)
        return x


class image_inference_dataset(torch.utils.data.Dataset):
    def __init__(self, list_path_file_image_input, image_resolution=448):
        self.list_path_file_image_input = list_path_file_image_input
        self.image_processor = process_image_for_infer(
            image_resolution=image_resolution
        )

    def __len__(self):
        return len(self.list_path_file_image_input)

    def __getitem__(self, i):
        return (
            self.list_path_file_image_input[i],
            self.image_processor.read_and_process_image(
                self.list_path_file_image_input[i]
            ),
        )


class wrap_inference_dataloader:
    def __init__(
        self,
        path_dir_input_prefix="/data/input",
        image_resolution=448,
    ):
        self.path_dir_input_prefix = path_dir_input_prefix
        self.notifier = notify_dataset(path_dir_prefix_input=self.path_dir_input_prefix)
        self.image_resolution = image_resolution
        self.starting = True

    def first(self):
        return list(
            get_list_path_file_image_under_dir(
                path_dir_input=self.path_dir_input_prefix
            )
        )

    def get(
        self,
        timeout=200,
    ):
        list_path_file_images = [
            self.path_dir_input_prefix + "/" + i for i in self.notifier(timeout)
        ]
        list_path_file_images = list(filter(is_path_file_image, list_path_file_images))
        return list_path_file_images

    def __call__(
        self,
        timeout=200,
        batch_size=16,
        num_workers=4,
    ):
        list_path_file_images = self.get()
        dataset = image_inference_dataset(
            list_path_file_image_input=list_path_file_images,
            image_resolution=self.image_resolution,
        )
        return torch.utils.data.DataLoader(
            dataset,
            batch_size=batch_size,
            shuffle=False,
            num_workers=num_workers,
        )
