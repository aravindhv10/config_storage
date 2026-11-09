#!/usr/bin/env python3
import os

try:
    __file__
except:
    basepath = os.path.abspath(".")
else:
    basepath = os.path.dirname(os.path.abspath(__file__))
import sys

sys.path.append(basepath)
from important_common_utils import *
from litwrap import lightning_wrapper
from litwrap import SimpleNetModule
import data
import lightning
import lightning.pytorch as pl
import model
import polars
import torch


def do_diffusion_pre_train_lightning():
    torch.set_float32_matmul_precision("high")
    net = SimpleNetModule()
    train_data = data_loader_pretrain_train
    test_data = data_loader_pretrain_test
    callback_checkpoint = lightning.pytorch.callbacks.ModelCheckpoint(
        dirpath="/mnt/huge/rd_pretrain_diffusion_30_October_2026",
        filename="RD_diffusion-{epoch:02d}-{val/loss:.6f}",
        verbose=True,
        save_top_k=4,
        mode="min",
        monitor="val/loss",
        # every_n_train_steps=1000,
    )
    trainer = lightning.Trainer(
        max_epochs=1024,
        # logger=csv_logger,
        # strategy=lightning.pytorch.strategies.DeepSpeedStrategy(
        #     offload_params_device="cpu",
        #     offload_optimizer_device="cpu",
        #     offload_optimizer=True,
        #     offload_parameters=True,
        #     stage=3,
        # ),
        # val_check_interval=1.0,
        check_val_every_n_epoch=1,
        val_check_interval=0.5,
        default_root_dir="/mnt/huge/rd_pretrain_diffusion_30_October_2026",
        accelerator="gpu",
        devices=-1,
        precision="32",
        # precision="32-true",
        callbacks=[callback_checkpoint],
    )
    trainer.fit(net, train_data, test_data)


def load_diffusion_pretrained_model(inpath):
    pretrained_model = SimpleNetModule.load_from_checkpoint(inpath)
    return pretrained_model.net.backbone


def load_classifier_pretrained_model(inpath, for_training=True):
    net = model.FullModel(for_training=for_training)
    net.backbone = load_diffusion_pretrained_model(inpath)
    return net


def do_finetune_lightning():
    torch.set_float32_matmul_precision("high")
    net = lightning_wrapper(inpath="./model.ckpt")
    train_data = dataloader_train
    test_data = dataloader_test
    callback_checkpoint = lightning.pytorch.callbacks.ModelCheckpoint(
        dirpath="/mnt/huge/rd_finetune_07_November_2026/training/output",
        filename="RDHF-{epoch:02d}-{val_accuracy:.6f}",
        verbose=True,
        save_top_k=4,
        mode="max",
        monitor="val_accuracy",
        # every_n_train_steps=1000,
    )
    trainer = lightning.Trainer(
        max_epochs=1024,
        # logger=csv_logger,
        # strategy=lightning.pytorch.strategies.DeepSpeedStrategy(
        #     offload_params_device="cpu",
        #     offload_optimizer_device="cpu",
        #     offload_optimizer=True,
        #     offload_parameters=True,
        #     stage=3,
        # ),
        # val_check_interval=1.0,
        check_val_every_n_epoch=1,
        default_root_dir="/mnt/huge/rd_finetune_07_November_2026/training",
        accelerator="gpu",
        devices=-1,
        precision="32",
        # precision="32-true",
        callbacks=[callback_checkpoint],
    )
    trainer.fit(net, train_data, test_data)


def resume_finetune_lightning():
    torch.set_float32_matmul_precision("high")
    net = lightning_wrapper(inpath="./model.ckpt")
    train_data = dataloader_train
    test_data = dataloader_test
    callback_checkpoint = lightning.pytorch.callbacks.ModelCheckpoint(
        dirpath="/mnt/huge/rd_finetune_07_November_2026/training/output",
        filename="RDHF-{epoch:02d}-{val_accuracy:.6f}",
        verbose=True,
        save_top_k=4,
        mode="max",
        monitor="val_accuracy",
        # every_n_train_steps=1000,
    )
    trainer = lightning.Trainer(
        max_epochs=1024,
        # logger=csv_logger,
        # strategy=lightning.pytorch.strategies.DeepSpeedStrategy(
        #     offload_params_device="cpu",
        #     offload_optimizer_device="cpu",
        #     offload_optimizer=True,
        #     offload_parameters=True,
        #     stage=3,
        # ),
        # val_check_interval=1.0,
        check_val_every_n_epoch=1,
        default_root_dir="/mnt/huge/rd_finetune_07_November_2026/training",
        accelerator="gpu",
        devices=-1,
        precision="32",
        # precision="32-true",
        callbacks=[callback_checkpoint],
    )
    trainer.fit(
        net,
        train_data,
        test_data,
        ckpt_path="./resume.ckpt",
    )


if os.path.exists("ALL_DATA/RD_HIGH_FIDALITY_EXTRACT_test.parquet"):
    df_hf_test = polars.read_parquet("ALL_DATA/RD_HIGH_FIDALITY_EXTRACT_test.parquet")
if os.path.exists("ALL_DATA/TRAINING_DATA_RD-V1_test_calm.parquet"):
    df_old_calm_test = polars.read_parquet(
        "ALL_DATA/TRAINING_DATA_RD-V1_test_calm.parquet"
    )
if os.path.exists("ALL_DATA/TRAINING_DATA_RD-V1_test_rd.parquet"):
    df_old_rd_test = polars.read_parquet("ALL_DATA/TRAINING_DATA_RD-V1_test_rd.parquet")
if os.path.exists("ALL_DATA/RD_HIGH_FIDALITY_EXTRACT_train.parquet"):
    df_hf_train = polars.read_parquet("ALL_DATA/RD_HIGH_FIDALITY_EXTRACT_train.parquet")
if os.path.exists("ALL_DATA/TRAINING_DATA_RD-V1_train_calm.parquet"):
    df_old_calm_train = polars.read_parquet(
        "ALL_DATA/TRAINING_DATA_RD-V1_train_calm.parquet"
    )
if os.path.exists("ALL_DATA/TRAINING_DATA_RD-V1_train_rd.parquet"):
    df_old_rd_train = polars.read_parquet(
        "ALL_DATA/TRAINING_DATA_RD-V1_train_rd.parquet"
    )
if os.path.exists("ALL_DATA_mean.64bin"):
    mu = data.load_bin64_file(path_file_bin64="ALL_DATA_mean.64bin").to(
        dtype=torch.float32
    )
if os.path.exists("ALL_DATA_sigma.64bin"):
    sigma = data.load_bin64_file(path_file_bin64="ALL_DATA_sigma.64bin").to(
        dtype=torch.float32
    )
if os.path.exists("./ALL_DATA"):
    if not (
        os.path.exists("./ALL_DATA_train.txt") and os.path.exists("./ALL_DATA_test.txt")
    ):
        inlist = data.get_list_path_bin16(inpath="./ALL_DATA")
        data.do_split_test_train(
            inlist,
            path_file_out_txt_train="./ALL_DATA_train.txt",
            path_file_out_txt_test="./ALL_DATA_test.txt",
            ratio=0.2,
        )
if os.path.exists("./ALL_DATA_test.txt"):
    list_path_bin16_test = data.read_list_path_bin16_from_path_txt(
        path_txt_input="./ALL_DATA_test.txt"
    )
    data_loader_pretrain_test = data.get_data_loader_pretrain(
        path_txt_list_bin16="./ALL_DATA_test.txt",
        mu=mu,
        sigma=sigma,
        batch_size=data.BATCH_SIZE_TEST,
        num_workers=2,
        prefetch_factor=1,
        for_training=True,
    )
if os.path.exists("./ALL_DATA_train.txt"):
    list_path_bin16_train = data.read_list_path_bin16_from_path_txt(
        path_txt_input="./ALL_DATA_train.txt"
    )
    data_loader_pretrain_train = data.get_data_loader_pretrain(
        path_txt_list_bin16="./ALL_DATA_train.txt",
        mu=mu,
        sigma=sigma,
        batch_size=data.BATCH_SIZE_TRAIN,
        num_workers=2,
        prefetch_factor=1,
        for_training=True,
    )
if (
    os.path.exists("ALL_DATA/RD_HIGH_FIDALITY_EXTRACT_test.parquet")
    and os.path.exists("ALL_DATA/TRAINING_DATA_RD-V1_test_calm.parquet")
    and os.path.exists("ALL_DATA/TRAINING_DATA_RD-V1_test_rd.parquet")
):
    dataloader_train = data.get_data_loader(
        df_hf=df_hf_train,
        df_old_calm=df_old_calm_train,
        df_old_rd=df_old_rd_train,
        batch_size=data.BATCH_SIZE_TRAIN_FINETUNE,
        num_workers=4,
        prefetch_factor=4,
        for_training=True,
        mu=mu,
        sigma=sigma,
    )
if (
    os.path.exists("ALL_DATA/RD_HIGH_FIDALITY_EXTRACT_train.parquet")
    and os.path.exists("ALL_DATA/TRAINING_DATA_RD-V1_train_calm.parquet")
    and os.path.exists("ALL_DATA/TRAINING_DATA_RD-V1_train_rd.parquet")
):
    dataloader_test = data.get_data_loader(
        df_hf=df_hf_test,
        df_old_calm=df_old_calm_test,
        df_old_rd=df_old_rd_test,
        batch_size=data.BATCH_SIZE_TEST,
        num_workers=2,
        prefetch_factor=1,
        for_training=False,
        mu=mu,
        sigma=sigma,
    )
