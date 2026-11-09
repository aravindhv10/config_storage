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
N_EPOCHS = 32
LEARNING_RATE = 0.00001
INPUT_IMAGE_RESOLUTION = 448
SAVE_FREQUENCY = 0.2
BATCH_SIZE_TRAIN = 8
BATCH_SIZE_TEST = BATCH_SIZE_TRAIN * 2
from important_common_utils import *
from torch.utils.data import DataLoader
from torch.utils.data import Dataset
import albumentations as A
import cv2
import einops
import json
import lightning as L
import numpy as np
import timm
import torch
import torchmetrics


def get_dataset_train(
    path_dir_input,
    repeat_factor=1,
    force_length=None,
):
    slave = CustomImageDataset(
        list_data_input=get_list_path_image_with_labels_under_dir(
            path_dir_prefix_input=path_dir_input
        ),
        repeat_factor=repeat_factor,
        force_length=force_length,
    )
    slave.train()
    return slave


def get_dataset_eval(
    path_dir_input,
    repeat_factor=1,
    force_length=None,
):
    slave = CustomImageDataset(
        list_data_input=get_list_path_image_with_labels_under_dir(
            path_dir_prefix_input=path_dir_input
        ),
        repeat_factor=repeat_factor,
        force_length=force_length,
    )
    slave.eval()
    return slave


def get_data_loader_eval(
    path_dir_input,
    batch_size,
    repeat_factor=1,
    force_length=None,
    num_workers=2,
):
    dataset = get_dataset_eval(
        path_dir_input=path_dir_input,
        repeat_factor=repeat_factor,
        force_length=force_length,
    )
    return DataLoader(
        dataset,
        batch_size=batch_size,
        shuffle=True,
        num_workers=num_workers,
    )


def get_data_loader_train(
    path_dir_input,
    batch_size,
    repeat_factor=1,
    force_length=None,
    num_workers=2,
):
    dataset = get_dataset_train(
        path_dir_input=path_dir_input,
        repeat_factor=repeat_factor,
        force_length=force_length,
    )
    return DataLoader(
        dataset,
        batch_size=batch_size,
        shuffle=True,
        num_workers=num_workers,
    )


def do_train_lightning(
    project_name,
    path_dir_store="/data/CLEAN_IMAGE_CLASSIFY/output",
    batch_size_train=None,
    batch_size_test=None,
    n_epochs=None,
):
    path_dir_store = path_dir_store + "/" + project_name
    # torch.set_float32_matmul_precision("medium")
    torch.set_float32_matmul_precision("high")
    if batch_size_train is None:
        batch_size_train = BATCH_SIZE_TRAIN
    if batch_size_test is None:
        batch_size_test = BATCH_SIZE_TEST
    if n_epochs is None:
        n_epochs = N_EPOCHS
    mkdir_safe(path_dir_store)
    num_prediction_classes = get_num_classes(
        path_file_json_labels="/data/CLEAN_IMAGE_CLASSIFY/DATA/train"
    )
    weights_tensor = reweight_calculator_image_tensor(
        path_file_label_json_input="/data/CLEAN_IMAGE_CLASSIFY/DATA/train/labels.json"
    )
    model = lightning_wrapper(
        num_classes=num_prediction_classes,
        weights_tensor=weights_tensor,
    )
    # model.do_compile()
    train_data = get_data_loader_train(
        path_dir_input="/data/CLEAN_IMAGE_CLASSIFY/DATA/train",
        batch_size=batch_size_train,
        repeat_factor=1,
        force_length=None,
        num_workers=4,
    )
    test_data = get_data_loader_eval(
        path_dir_input="/data/CLEAN_IMAGE_CLASSIFY/DATA/test",
        batch_size=batch_size_test,
        repeat_factor=1,
        force_length=None,
        num_workers=4,
    )
    # val_data = get_data_loader(
    #     path_dir_input="/data/input/val",
    #     batch_size=batch_size_test,
    #     train_mode=False,
    #     repeat_factor=1,
    #     force_length=None,
    # )
    callback_checkpoint = L.pytorch.callbacks.ModelCheckpoint(
        dirpath=path_dir_store + "/checkpoints",
        filename=project_name + "-{epoch:02d}-{val_accuracy:.6f}",
        verbose=True,
        save_top_k=8,
        mode="max",
        monitor="val_accuracy",
        # every_n_train_steps=1000,
    )
    trainer = L.Trainer(
        max_epochs=n_epochs,
        val_check_interval=1.0,
        default_root_dir=path_dir_store,
        accelerator="gpu",
        devices=-1,
        precision="32",
        callbacks=[callback_checkpoint],
    )
    trainer.fit(
        model,
        train_data,
        test_data,
    )


def resume_train_lightning(
    project_name,
    path_dir_store="/data/CLEAN_IMAGE_CLASSIFY/output",
    batch_size_train=None,
    batch_size_test=None,
    n_epochs=None,
):
    path_dir_store = path_dir_store + "/" + project_name
    # torch.set_float32_matmul_precision("medium")
    torch.set_float32_matmul_precision("high")
    if batch_size_train is None:
        batch_size_train = BATCH_SIZE_TRAIN
    if batch_size_test is None:
        batch_size_test = BATCH_SIZE_TEST
    if n_epochs is None:
        n_epochs = N_EPOCHS
    mkdir_safe(path_dir_store)
    num_prediction_classes = get_num_classes(
        path_file_json_labels="/data/CLEAN_IMAGE_CLASSIFY/DATA/train"
    )
    weights_tensor = reweight_calculator_image_tensor(
        path_file_label_json_input="/data/CLEAN_IMAGE_CLASSIFY/DATA/train/labels.json"
    )
    model = lightning_wrapper(
        num_classes=num_prediction_classes,
        weights_tensor=weights_tensor,
    )
    model.do_compile()
    train_data = get_data_loader_train(
        path_dir_input="/data/CLEAN_IMAGE_CLASSIFY/DATA/train",
        batch_size=batch_size_train,
        repeat_factor=1,
        force_length=None,
        num_workers=4,
    )
    test_data = get_data_loader_eval(
        path_dir_input="/data/CLEAN_IMAGE_CLASSIFY/DATA/test",
        batch_size=batch_size_test,
        repeat_factor=1,
        force_length=None,
        num_workers=4,
    )
    # val_data = get_data_loader(
    #     path_dir_input="/data/input/val",
    #     batch_size=batch_size_test,
    #     train_mode=False,
    #     repeat_factor=1,
    #     force_length=None,
    # )
    callback_checkpoint = L.pytorch.callbacks.ModelCheckpoint(
        dirpath=path_dir_store + "/checkpoints",
        filename=project_name + "-{epoch:02d}-{val_accuracy:.6f}",
        verbose=True,
        save_top_k=8,
        mode="max",
        monitor="val_accuracy",
        # every_n_train_steps=1000,
    )
    trainer = L.Trainer(
        max_epochs=n_epochs,
        val_check_interval=1.0,
        default_root_dir=path_dir_store,
        accelerator="gpu",
        devices=1,
        precision="32",
        callbacks=[callback_checkpoint],
    )
    trainer.fit(
        model,
        train_data,
        test_data,
        ckpt_path="/data/CLEAN_IMAGE_CLASSIFY/output/cv_usability/checkpoints/cv_usability-epoch=08-val_accuracy=0.825216.ckpt",
    )


def load_trained_model_from_checkpoint(path_file_ckpt):
    return lightning_wrapper.load_from_checkpoint(
        checkpoint_path=path_file_ckpt,
        strict=True,
        num_classes=2,
    )


def get_exported_program(
    path_file_ckpt,
    batch_size=8,
    image_resolution=448,
):
    model = load_trained_model_from_checkpoint(path_file_ckpt=path_file_ckpt)
    model.eval()
    model.mode_forward_opencv_onnx()
    with torch.inference_mode():
        device = "cpu"
        dtype = torch.float32
        inductor_configs = {}
        if torch.cuda.is_available():
            device = "cuda"
            dtype = torch.bfloat16
            inductor_configs["max_autotune"] = True
        print("device = ", device)
        print("dtype = ", dtype)
        model = model.to(
            device=device,
            dtype=dtype,
        )
        x = torch.rand(
            (
                batch_size,
                image_resolution,
                image_resolution,
                3,
            ),
            device=device,
            dtype=dtype,
        )
        exported_program = torch.export.export(
            model.model,
            (x,),
            strict=True,
        )
        return (exported_program, inductor_configs)


def compile_to_aot_inductor(
    path_file_ckpt,
    path_file_pt2_output,
    batch_size=8,
    image_resolution=448,
):
    (
        exported_program,
        inductor_configs,
    ) = get_exported_program(
        path_file_ckpt,
        batch_size=8,
        image_resolution=448,
    )
    path = torch._inductor.aoti_compile_and_package(
        exported_program,
        package_path=path_file_pt2_output,
        inductor_configs=inductor_configs,
    )


def export_to_onnx(
    path_file_checkpoint_input,
    path_file_onnx_output,
    num_classes=3,
    batch_size=None,
    image_resolution=None,
):
    if image_resolution is None:
        image_resolution = INPUT_IMAGE_RESOLUTION
    model = lightning_wrapper(num_classes=num_classes)
    model.do_compile()
    res = torch.load(path_file_checkpoint_input)
    model.load_state_dict(res["state_dict"])
    model.eval()
    model.mode_forward_opencv_onnx()
    if batch_size is None:
        batch_size = 4
    input_sample = torch.randn(
        (
            batch_size,
            image_resolution,
            image_resolution,
            3,
        ),
    )
    input_sample *= 255.0
    input_sample = input_sample.to(dtype=torch.uint8)
    batch_dim = torch.export.Dim("batch_size", min=1)
    # 2. Define the dynamic shape for the input tensor
    dynamic_shapes = {"x": (batch_dim, image_resolution, image_resolution, 3)}
    dynamic_axes = {
        "input": {0: "batch_size"},  # Batch size is the 0-th dimension of the input
        "output": {0: "batch_size"},  # Batch size is the 0-th dimension of the output
    }
    model.to_onnx(
        path_file_onnx_output,
        input_sample,
        export_params=True,
        input_names=["input"],
        output_names=["output"],
        dynamic_axes=dynamic_axes,
        dynamo=True,
    )
    print(
        f"Model successfully exported to {path_file_onnx_output} with dynamic batch size."
    )


def infer_on_all_files_under_dir(path_dir_input, model, device="cuda:1", batch_size=4):
    model.to(device)
    data_loader = get_data_loader_eval(
        path_dir_input=path_dir_input,
        batch_size=batch_size,
        repeat_factor=1,
        force_length=None,
        num_workers=2,
    )
    for i in data_loader:
        paths = i[2]
        preds = model(i[0].to(device)).detach().cpu()
        for index, path in enumerate(paths):
            pred = preds[index, :]
            outdict = {
                "class": torch.argmax(pred).item(),
                "negative": pred[0].item(),
                "positive": pred[1].item(),
            }
            with open(path + ".json", "w", encoding="utf-8") as f:
                json.dump(
                    obj=outdict,
                    fp=f,
                )


class augmenter:
    def train(self):
        self.transform = A.Compose(
            [
                # Image processing
                A.LongestMaxSize(max_size=self.image_resolution),
                A.PadIfNeeded(
                    min_height=448,
                    min_width=448,
                    border_mode=cv2.BORDER_WRAP,
                    value=0,  # This is ignored when using BORDER_WRAP
                ),
                # Main augmentation
                A.D4(p=1.0),
                A.ChannelDropout(p=0.1),
                A.ChannelShuffle(p=0.1),
                A.Spatter(p=0.2),
                A.ToGray(
                    num_output_channels=3,
                    method="weighted_average",
                    p=0.2,
                ),
                A.RGBShift(p=0.1),
                A.HueSaturationValue(p=0.3),
                A.ColorJitter(p=0.3),
                A.Rotate(
                    limit=180,
                    border_mode=cv2.BORDER_REFLECT,
                    p=0.5,
                ),
                # To torch tensor
                A.ToTensorV2(),
            ]
        )

    def eval(self):
        self.transform = A.Compose(
            [
                # Image processing
                A.LongestMaxSize(max_size=self.image_resolution),
                A.PadIfNeeded(
                    min_height=448,
                    min_width=448,
                    border_mode=cv2.BORDER_WRAP,
                    value=0,  # This is ignored when using BORDER_WRAP
                ),
                A.HorizontalFlip(p=0.5),
                # To torch tensor
                A.ToTensorV2(),
            ]
        )

    def __init__(
        self,
        image_resolution=None,
    ):
        if image_resolution is None:
            image_resolution = INPUT_IMAGE_RESOLUTION
        self.image_resolution = image_resolution

    def __call__(
        self,
        x,
    ):
        augmented_data = self.transform(image=x)
        x = augmented_data["image"]
        return x


class CustomImageDataset(torch.utils.data.Dataset):
    def train(self):
        self.slave_augmenter.train()

    def eval(self):
        self.slave_augmenter.eval()

    def __init__(
        self,
        list_data_input,
        weight_calculator=None,
        repeat_factor=1,
        force_length=None,
    ):
        self.force_length = force_length
        self.list_data_input = list_data_input
        self.repeat_factor = repeat_factor
        self.slave_augmenter = augmenter()
        self.actual_length = len(self.list_data_input)

    def __len__(self):
        if self.force_length is not None:
            return self.force_length
        else:
            return self.actual_length * self.repeat_factor

    def getitem(
        self,
        i,
    ):
        i = i % self.actual_length
        (
            path_file_image,
            label,
        ) = self.list_data_input[i]
        image = read_image(path_file_image_input=path_file_image)
        image = self.slave_augmenter(image)
        return (
            image,
            label,
            path_file_image,
        )

    def __getitem__(
        self,
        i,
    ):
        return self.getitem(i)


class model_full(torch.nn.Module):
    def setup_stat_parameters_as_float(self):
        self.mean = (
            0.48145466,
            0.4578275,
            0.40821073,
        )
        self.std = (
            0.26862954,
            0.26130258,
            0.27577711,
        )

    def setup_stat_parameters_as_torch(self):
        self.mean = torch.tensor(
            (
                0.48145466,
                0.4578275,
                0.40821073,
            ),
            dtype=torch.float32,
        )
        self.std = torch.tensor(
            (
                0.26862954,
                0.26130258,
                0.27577711,
            ),
            dtype=torch.float32,
        )

    def get_dtype(self):
        return next(self.timm_model.parameters()).dtype

    def forward_CHW(
        self,
        x,
    ):
        x = x.to(dtype=self.get_dtype())
        for i in range(3):
            x[:, i, :, :] = ((x[:, i, :, :] / 255.0) - self.mean[i]) / self.std[i]
        x = self.timm_model(x)
        return x

    def forward_HWC(
        self,
        x,
    ):
        x = einops.rearrange(
            x,
            "B H W C -> B C H W",
        )
        return self.forward_CHW(x)

    def forward_onnx(
        self,
        x,
    ):
        return torch.nn.functional.softmax(
            self.forward_HWC(x),
            dim=1,
        )

    def forward_auto(
        self,
        x,
    ):
        if (
            (x.shape[1] == 3)
            and (x.shape[2] == INPUT_IMAGE_RESOLUTION)
            and (x.shape[3] == INPUT_IMAGE_RESOLUTION)
        ):
            return self.forward_CHW(x)
        elif (
            (x.shape[1] == INPUT_IMAGE_RESOLUTION)
            and (x.shape[2] == INPUT_IMAGE_RESOLUTION)
            and (x.shape[3] == 3)
        ):
            return self.forward_HWC(x)
        else:
            print("*ERROR* Donot understand the data format")
            return None

    def mode_forward_auto(self):
        self.forward = self.forward_auto

    def mode_forward_HWC(self):
        self.forward = self.forward_HWC

    def mode_forward_CHW(self):
        self.forward = self.forward_CHW

    def mode_forward_opencv_onnx(self):
        self.forward = self.forward_onnx

    def __init__(
        self,
        num_classes,
    ):
        super().__init__()
        self.setup_stat_parameters_as_float()
        self.timm_model = timm.create_model(
            "eva02_large_patch14_448.mim_m38m_ft_in22k_in1k",
            num_classes=num_classes,
            pretrained=True,
        )
        self.mode_forward_auto()


class lightning_wrapper(L.LightningModule):
    def configure_optimizers(self):
        optimizer = torch.optim.AdamW(
            self.model.parameters(),
            lr=LEARNING_RATE,
        )
        return optimizer

    def mode_forward_auto(self):
        self.model.mode_forward_auto()

    def mode_forward_HWC(self):
        self.model.mode_forward_HWC()

    def mode_forward_CHW(self):
        self.model.mode_forward_CHW()

    def mode_forward_opencv_onnx(self):
        self.model.mode_forward_opencv_onnx()

    def do_compile(self):
        self.model = torch.compile(
            self.model,
            mode="max-autotune",
        )

    def do_compile_light(self):
        self.model = torch.compile(self.model)

    def __init__(
        self,
        num_classes,
        weights_tensor=None,
    ):
        super().__init__()
        if weights_tensor is None:
            weights_tensor = torch.ones((num_classes), dtype=torch.float32)
        self.weights_tensor = weights_tensor
        self.model = model_full(num_classes=num_classes)
        self.loss = torch.nn.CrossEntropyLoss(weight=self.weights_tensor)

    def forward(
        self,
        x,
    ):
        return self.model(x)

    def training_step(
        self,
        batch,
        batch_idx,
    ):
        (
            x,
            y,
            path,
        ) = batch
        r = self.model(x)
        d = self.loss(
            r,
            y,
        )
        self.log(
            "train_loss",
            d,
        )
        return d

    def val_test_step(
        self,
        batch,
        batch_idx,
        step_label,
    ):
        (
            x,
            y,
            path,
        ) = batch
        r = self.model(x)
        (l, t) = get_weighted_accuracy_refweight(X=r, Y=y, W=self.weights_tensor)
        self.log(
            step_label,
            l,
            batch_size=t,
        )
        return r

    def test_step(
        self,
        batch,
        batch_idx,
    ):
        self.val_test_step(
            batch=batch,
            batch_idx=batch_idx,
            step_label="test_accuracy",
        )

    def validation_step(
        self,
        batch,
        batch_idx,
    ):
        self.val_test_step(
            batch=batch,
            batch_idx=batch_idx,
            step_label="val_accuracy",
        )

    def predict_step(
        self,
        batch,
        batch_idx,
    ):
        return self.model(batch)
