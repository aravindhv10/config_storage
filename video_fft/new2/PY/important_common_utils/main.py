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
import numpy as np

try:
    import cv2
except:
    print("cv2 not found")
try:
    import torch
except:
    print("torch not found")
try:
    from safetensors.torch import load_file
    from safetensors.torch import save_file
except:
    print("safetensors not found")
try:
    import einops
except:
    print("einops not found")
try:
    import albumentations as A
except:
    print("unable to import albumentationsx")
try:
    import inotify_simple
except:
    print("unable to import inotify_simple")
INPUT_IMAGE_RESOLUTION = 448
FLAG_AMD_GPU = 1
FLAG_NVIDIA_GPU = 2
from datetime import datetime
from pathlib import Path
import blake3
import datafusion
import fcntl
import json
import mmap
import polars
import shutil
import subprocess
import time


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
    return blake3.blake3()


def hash_list_file(list_path_file_input):
    main_hasher = get_hasher()
    for path_file_input in list_path_file_input:
        file_size = os.path.getsize(path_file_input)
        if file_size > 0:
            with open(
                path_file_input,
                "rb",
            ) as f:
                with mmap.mmap(
                    f.fileno(),
                    length=0,
                    access=mmap.ACCESS_READ,
                ) as mm:
                    main_hasher.update(mm)
    return main_hasher.hexdigest()


def hash_file(path_file_input):
    return hash_list_file(list_path_file_input=(path_file_input,))


def get_blake3_hash(path_file_input):
    file_size = os.path.getsize(path_file_input)
    if file_size == 0:
        return blake3.blake3().hexdigest()
    with open(path_file_input, "rb") as f:
        with mmap.mmap(f.fileno(), length=0, access=mmap.ACCESS_READ) as mm:
            hasher = blake3.blake3()
            hasher.update(mm)
            return hasher.hexdigest()


def csv_2_parquet_polars(path_file_csv_input, path_file_parquet_output):
    polars.read_csv(
        source=path_file_csv_input,
        has_header=True,
        separator=",",
    ).write_parquet(
        file=path_file_parquet_output,
        compression="zstd",
        compression_level=18,
    )


def tsv_2_parquet_polars(path_file_tsv_input, path_file_parquet_output):
    polars.read_csv(
        source=path_file_tsv_input,
        has_header=True,
        separator="\t",
    ).write_parquet(
        file=path_file_parquet_output,
        compression="zstd",
        compression_level=18,
    )


def csv_2_parquet_datafusion(path_file_csv_input, path_file_parquet_output):
    ctx = datafusion.SessionContext()
    ctx.register_csv(
        name="maintable",
        path=path_file_csv_input,
        has_header=True,
        delimiter=",",
        schema_infer_max_records=999999999,
        file_extension=".csv",
    )
    ctx.sql("SELECT * from maintable;").write_parquet(
        path=path_file_parquet_output,
        compression="zstd",
        compression_level=18,
    )


def tsv_2_parquet_datafusion(path_file_tsv_input, path_file_parquet_output):
    ctx = datafusion.SessionContext()
    ctx.register_csv(
        name="maintable",
        path=path_file_tsv_input,
        has_header=True,
        delimiter="\t",
        schema_infer_max_records=999999999,
        file_extension=".tsv",
    )
    ctx.sql("SELECT * from maintable;").write_parquet(
        path=path_file_parquet_output,
        compression="zstd",
        compression_level=18,
    )


def convert_csv_2_parquet(path_file_csv_input, use_polars=False):
    print("START hashing")
    file_hash = get_blake3_hash(path_file_input=path_file_csv_input)
    print("DONE hashing ", file_hash)
    path_file_parquet_output_hashed = file_hash + ".parquet"
    if not os.path.exists(path_file_parquet_output_hashed):
        print("Saving file")
        if use_polars:
            csv_2_parquet_polars(
                path_file_csv_input,
                path_file_parquet_output_hashed,
            )
        else:
            csv_2_parquet_datafusion(
                path_file_csv_input,
                path_file_parquet_output_hashed,
            )
        print("Saved file")
    return path_file_parquet_output_hashed


def convert_tsv_2_parquet(path_file_tsv_input, use_polars=False):
    print("START hashing")
    file_hash = get_blake3_hash(path_file_input=path_file_tsv_input)
    print("DONE hashing ", file_hash)
    path_file_parquet_output_hashed = file_hash + ".parquet"
    if not os.path.exists(path_file_parquet_output_hashed):
        print("Saving file")
        if use_polars:
            tsv_2_parquet_polars(
                path_file_tsv_input,
                path_file_parquet_output_hashed,
            )
        else:
            tsv_2_parquet_datafusion(
                path_file_tsv_input,
                path_file_parquet_output_hashed,
            )
        print("Saved file")
    return path_file_parquet_output_hashed


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


def ffmpeg_probe(path: str) -> tuple[int, int]:
    result = subprocess.run(
        [
            "ffprobe",
            "-v",
            "error",
            "-select_streams",
            "v:0",
            "-show_entries",
            "stream=width,height,duration",
            "-of",
            "json",
            path,
        ],
        capture_output=True,
        text=True,
        check=True,
    )
    stream = json.loads(result.stdout)["streams"][0]
    duration = stream["duration"]
    (
        T,
        Y,
        X,
    ) = (
        float(duration),
        stream["height"],
        stream["width"],
    )
    return (
        T,
        Y,
        X,
    )


def ffmpeg_transcode(src: str, dst: str, fps: int) -> None:
    subprocess.run(
        [
            "ffmpeg",
            "-loglevel",
            "error",
            "-y",
            "-i",
            src,
            "-vf",
            f"fps={fps},scale=1280:720",
            "-nostdin",
            "-an",
            "-f",
            "rawvideo",
            "-pix_fmt",
            "rgb24",
            dst,
        ],
        check=True,
    )


def ffmpeg_load(path: str, Y: int, X: int) -> np.ndarray:
    frame_bytes = Y * X * 3
    T = Path(path).stat().st_size // frame_bytes
    if T > 0:
        return np.memmap(
            path,
            dtype=np.uint8,
            mode="r",
            shape=(T, Y, X, 3),
        )
    else:
        return None


def ffmpeg_video_2_np(
    path_file_video_input,
    fps=8,
    force=False,
    max_duration=None,
):
    file_hash = hash_file(path_file_input=path_file_video_input)
    path_file_raw_tmp = f"/dev/shm/{file_hash}.raw"
    ffmpeg_transcode(src=path_file_video_input, dst=path_file_raw_tmp, fps=fps)
    array = ffmpeg_load(path=path_file_raw_tmp, Y=720, X=1280)
    os.unlink(path=path_file_raw_tmp)
    return array


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
        return (
            path_input.endswith(".mp4")
            or path_input.endswith(".avi")
            or path_input.endswith(".mkv")
        )
    else:
        return False


def is_path_file_safetensors(path_input):
    if is_path_file(path_input=path_input):
        path_input = path_input.lower()
        return path_input.endswith(".safetensors")
    else:
        return False


def is_path_file_bin(path_input):
    if is_path_file(path_input=path_input):
        path_input = path_input.lower()
        return path_input.endswith(".bin")
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


def get_list_path_file_bin_under_dir(path_dir_input):
    return filter(
        is_path_file_bin,
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


def reweight_calculator(path_file_label_json_input):
    return reweight_calculator_generic(
        path_file_label_json_input, get_list_path_file_under_dir
    )


def reweight_calculator_tensor(path_file_label_json_input):
    return reweight_calculator(path_file_label_json_input).get_tensor()


def reweight_calculator_image(path_file_label_json_input):
    return reweight_calculator_generic(
        path_file_label_json_input, get_list_path_file_image_under_dir
    )


def reweight_calculator_image_tensor(path_file_label_json_input):
    return reweight_calculator_image(
        path_file_label_json_input=path_file_label_json_input
    ).get_tensor()


def reweight_calculator_safetensors(path_file_label_json_input):
    return reweight_calculator_generic(
        path_file_label_json_input, get_list_path_file_safetensors_under_dir
    )


def reweight_calculator_safetensors_tensor(path_file_label_json_input):
    return reweight_calculator_safetensors(
        path_file_label_json_input=path_file_label_json_input
    ).get_tensor()


def reweight_calculator_bin(path_file_label_json_input):
    return reweight_calculator_generic(
        path_file_label_json_input, get_list_path_file_bin_under_dir
    )


def reweight_calculator_bin_tensor(path_file_label_json_input):
    return reweight_calculator_bin(
        path_file_label_json_input=path_file_label_json_input
    ).get_tensor()


def reweight_calculator_video(path_file_label_json_input):
    return reweight_calculator_generic(
        path_file_label_json_input, get_list_path_file_video_under_dir
    )


def reweight_calculator_video_tensor(path_file_label_json_input):
    return reweight_calculator_video(
        path_file_label_json_input=path_file_label_json_input
    ).get_tensor()


def get_weighted_accuracy(X, Y, W):
    if Y.shape != W.shape:
        print("Y.shape[0] != W.shape[0]! Disaster!!!")
        return None
    if (len(X.shape) == 2) and (len(Y.shape) == 1) and (X.shape[0] == Y.shape[0]):
        X = torch.topk(X, k=1).indices.flatten()
    correct = torch.sum((X == Y).to(dtype=torch.float32) * W).item()
    total = torch.sum(W).item()
    return (correct / total, total)


def get_weighted_accuracy_refweight(X, Y, W):
    weights = W.to(device=Y.device)[Y.to(dtype=torch.int32)]
    return get_weighted_accuracy(X=X, Y=Y, W=weights)


def get_num_classes(path_file_json_labels):
    write_classes_json_if_not_exist(path_dir_prefix_input=path_file_json_labels)
    res = open(
        path_file_json_labels + "/labels.json",
        "r",
        encoding="utf-8",
    ).read()
    res = json.loads(res)
    return len(res.values())


def check_type_of_accelerator():
    if torch.cuda.is_available():
        if (torch.version.cuda is None) and (torch.version.hip is None):
            return 0
        elif (torch.version.cuda is not None) and (torch.version.hip is None):
            return FLAG_NVIDIA_GPU
        elif (torch.version.cuda is None) and (torch.version.hip is not None):
            return FLAG_AMD_GPU
        elif (torch.version.cuda is not None) and (torch.version.hip is not None):
            return FLAG_AMD_GPU | FLAG_NVIDIA_GPU
    else:
        return 0


try:

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
except:
    print("Torch not found")


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
        self.watch_flags = (
            0
            | inotify_simple.flags.ATTRIB
            | inotify_simple.flags.CLOSE_NOWRITE
            | inotify_simple.flags.CLOSE_WRITE
            | inotify_simple.flags.MOVED_TO
        )
        self.inotify = inotify_simple.INotify()
        self.wd = self.inotify.add_watch(
            path_dir_prefix_input,
            self.watch_flags,
        )
        self.first_run = True

    def __call__(
        self,
        waittime=None,
        timeout=200,
        batch_size=16,
    ):
        looper = set()
        if self.first_run:
            for entry in os.scandir(self.path_dir_prefix_input):
                if entry.is_file():
                    looper.add(entry.name)
            self.first_run = False
        while not looper:
            events = self.inotify.read(timeout=waittime)
            if not events:
                if waittime is not None:
                    return looper
            else:
                for event in events:
                    if event.name:
                        looper.add(event.name)
        start_time = time.monotonic()
        while len(looper) < batch_size:
            elapsed = (time.monotonic() - start_time) * 1000
            remaining = timeout - elapsed
            if remaining <= 0:
                break
            events = self.inotify.read(timeout=int(remaining))
            if not events:
                break
            for event in events:
                if event.name:
                    looper.add(event.name)
        return looper


class notify_dataset_old:
    def __init__(self, path_dir_prefix_input):
        self.path_dir_prefix_input = path_dir_prefix_input
        flags_all = (
            0
            | inotify_simple.flags.ACCESS
            | inotify_simple.flags.ATTRIB
            | inotify_simple.flags.CLOSE_NOWRITE
            | inotify_simple.flags.CLOSE_WRITE
            | inotify_simple.flags.CREATE
            | inotify_simple.flags.DELETE
            | inotify_simple.flags.MODIFY
            | inotify_simple.flags.MOVED_FROM
            | inotify_simple.flags.MOVED_TO
            | inotify_simple.flags.OPEN
        )
        self.watch_flags = (
            0
            | inotify_simple.flags.ATTRIB
            | inotify_simple.flags.CLOSE_NOWRITE
            | inotify_simple.flags.CLOSE_WRITE
            | inotify_simple.flags.MOVED_TO
        )
        self.inotify = inotify_simple.INotify()
        self.wd = self.inotify.add_watch(
            path_dir_prefix_input,
            self.watch_flags,
        )
        self.main = self.start

    def start(
        self,
        timeout=200,
        batch_size=16,
    ):
        self.main = self.watch
        looper = set(i for i in os.listdir(self.path_dir_prefix_input) if len(i) > 0)
        start_time = datetime.now()
        end_time = datetime.now()
        diff = end_time - start_time
        timediff = (diff.seconds * 1000) + (diff.microseconds / 1000)
        while (timediff < timeout) and (len(looper) < batch_size):
            for i in self.inotify.read(timeout=timeout):
                if len(i.name) > 0:
                    looper.add(i.name)
            end_time = datetime.now()
            diff = end_time - start_time
            timediff = (diff.seconds * 1000) + (diff.microseconds / 1000)
        return looper

    def watch(
        self,
        timeout=200,
        batch_size=16,
    ):
        looper = set(i.name for i in self.inotify.read() if len(i.name) > 0)
        start_time = datetime.now()
        end_time = datetime.now()
        diff = end_time - start_time
        timediff = (diff.seconds * 1000) + (diff.microseconds / 1000)
        while (timediff < timeout) and (len(looper) < batch_size):
            for i in self.inotify.read(timeout=timeout):
                if len(i.name) > 0:
                    looper.add(i.name)
            end_time = datetime.now()
            diff = end_time - start_time
            timediff = (diff.seconds * 1000) + (diff.microseconds / 1000)
        return looper

    def __call__(
        self,
        timeout=200,
        batch_size=16,
    ):
        return self.main(timeout)


class reweight_calculator_generic:
    def __init__(self, path_file_label_json_input, main_fun):
        self.path_file_label_json_input = path_file_label_json_input
        self.path_dir_prefix = os.path.dirname(path_file_label_json_input)
        with open(self.path_file_label_json_input, "r", encoding="utf-8") as f:
            res = f.read()
            self.labels = json.loads(res)
        self.counts = {}
        self.total_sum = 0
        for i in self.labels.keys():
            path_dir_final = self.path_dir_prefix + "/" + i
            n_files = len(list(main_fun(path_dir_input=path_dir_final)))
            self.counts[self.labels[i]] = n_files
            self.total_sum += n_files
        self.weights = {}
        for i in self.labels.keys():
            self.weights[self.labels[i]] = self.total_sum / self.counts[self.labels[i]]
        with open(
            os.path.dirname(path_file_label_json_input) + "/weights.json",
            "w",
            encoding="utf-8",
        ) as f:
            f.write(json.dumps(self.weights))

    def __getitem__(self, idx):
        return self.weights[idx]

    def __len__(self):
        return len(self.labels.keys())

    def get_tensor(self):
        length = len(self.labels.keys())
        ret = torch.zeros(length, dtype=torch.float32)
        for i in range(length):
            ret[i] = self.weights[i]
        return ret


class WeightedAccuracyCalculator:
    def __init__(self, weights):
        self.weights = weights
        self.confusion_matrix = torch.zeros(
            (self.weights[0], self.weights[0]),
            dtype=torch.float32,
        )

    def __call__(self, X, Y, W):
        X = torch.topk(X, k=1).indices.flatten()
        for i, (x, y) in enumerate(zip(X, Y)):
            self.confusion_matrix[y, x] += W[i]


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


try:

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
except:
    print("No torch found")


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
