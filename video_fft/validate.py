#!/usr/bin/env python3
import numpy as np
import torch

APPROXIMATE_LENGTH = 20
FPS = 8.0
FREQ_LIMIT = 3.0
LR = 0.000001
N_CHANNELS = 3
N_CLASS_OUTPUT = 3
SIZE_X = 1280
SIZE_Y = 720

N_FFT_MODES_T = int(APPROXIMATE_LENGTH * FREQ_LIMIT)  # 60

N_CHANNELS_FFT = N_CHANNELS * 2  # 6 (real and imag for every color channel)

SIZE_MAX = max(SIZE_X, SIZE_Y)  # 1280
SIZE_MIN = min(SIZE_X, SIZE_Y)  # 720

SIZE_DIFF = SIZE_MAX - SIZE_MIN
SIZE_TRUNCATED = SIZE_MAX >> 3  # 160

SIZE_START = (SIZE_MAX - SIZE_TRUNCATED) >> 1
SIZE_END = SIZE_START + SIZE_TRUNCATED

MODEL_TMP_DIMENSION = 512


def do_pad_video(tensor_video):  # N H W C
    B, H, W, C = list(tensor_video.shape)
    if H < W:
        tensor_video_pad = torch.nn.functional.pad(
            input=tensor_video,
            pad=(0, 0, 0, 0, 0, W - H),
        )
    elif W < H:
        tensor_video_pad = torch.nn.functional.pad(
            input=tensor_video,
            pad=(0, 0, 0, H - W, 0, 0),
        )

    return tensor_video_pad


def compress_video_tensor(tensor_video):

    if tensor_video is None:
        return None

    tensor_video_pad = do_pad_video(tensor_video=tensor_video)
    del tensor_video

    tensor_video_pad = torch.permute(
        tensor_video_pad,
        (
            3,
            1,
            2,
            0,
        ),
    )

    freq = torch.fft.rfftfreq(n=tensor_video_pad.shape[3], d=1.0 / FPS)
    valid = (0 <= freq) & (freq < FREQ_LIMIT)
    del freq
    n = valid.sum().item()
    del valid

    tensor_video_fft = torch.fft.rfftn(tensor_video_pad)
    del tensor_video_pad
    tensor_video_fft = tensor_video_fft[:, :, :, 0:n]

    tensor_video_fft = torch.fft.fftshift(
        tensor_video_fft,
        dim=(
            0,
            1,
            2,
        ),
    )
    compressed_tensor_video_fft = tensor_video_fft[
        :, SIZE_START:SIZE_END, SIZE_START:SIZE_END, :
    ]
    compressed_tensor_video_fft = torch.cat(
        (compressed_tensor_video_fft.abs(), compressed_tensor_video_fft.angle())
    )
    compressed_tensor_video_fft = torch.nn.functional.interpolate(
        input=compressed_tensor_video_fft.unsqueeze(0),
        size=(SIZE_TRUNCATED, SIZE_TRUNCATED, int(N_FFT_MODES_T)),
        mode="trilinear",
    ).squeeze()
    return compressed_tensor_video_fft


res = np.fromfile("video.mp4.raw", dtype=np.uint8)
vid = res.reshape((-1, 720, 1280, 3))[0:40, :, :, :]
vid = torch.from_numpy(vid)
vid = compress_video_tensor(vid)
res = vid.detach().numpy()
res2 = np.fromfile("video.bin", dtype=np.float32).reshape(6, 160, 160, 60)

diff = res2 - res

np.sum(np.abs(diff))
np.sum(np.abs(res))
np.sum(np.abs(res2))
