fn do_pad_video(tensor_video: &tch::Tensor) -> anyhow::Result<tch::Tensor> {
    let size: Vec<i64> = tensor_video.size();
    let (_b, h, w, _c) = (size[0], size[1], size[2], size[3]);

    let padded: tch::Tensor = {
        if h < w {
            tensor_video.f_pad(&[0, 0, 0, 0, 0, w - h], "constant", 0.0)?
        } else if w < h {
            tensor_video.f_pad(&[0, 0, 0, h - w, 0, 0], "constant", 0.0)?
        } else {
            tensor_video.shallow_clone()
        }
    };

    Ok(padded)
}

fn compress_video_tensor(
    tensor_video: &tch::Tensor,
    fps: f64,
    freq_limit: f64,
) -> anyhow::Result<tch::Tensor> {
    let tensor_video_pad: tch::Tensor = do_pad_video(tensor_video)?;

    let tensor_video_permuted: tch::Tensor = {
        " For permuting: ";
        " T0 H1 W2 C3 "; // INPUT
        " C3 H1 W2 T0 "; // OUTPUT
        tensor_video_pad.permute(/*dims =*/ &[3, 1, 2, 0])
    };

    let n_dim3: i64 = tensor_video_permuted.size()[3];
    let freq_step: f64 = fps / (n_dim3 as f64);

    let tensor_video_fft: tch::Tensor = {
        let s: Vec<i64> = tensor_video_permuted.size();
        let dim: Vec<i64> = vec![0, 1, 2, 3];
        let norm: &str = "forward";

        tensor_video_permuted.fft_rfftn(/*s =*/ s, /*dim =*/ dim, /*norm =*/ norm)
    };

    let tensor_video_fft: tch::Tensor = {
        let dim = 3;
        let start = 0;

        let mut length: i64 = 0;
        for i in 0..=(n_dim3 / 2) {
            if ((i as f64) * freq_step) < freq_limit {
                length += 1;
            } else {
                break;
            }
        }

        tensor_video_fft.narrow(
            /*dim =*/ dim, /*start =*/ start, /*length =*/ length,
        )
    };

    let tensor_video_fft: tch::Tensor = {
        let dim: Vec<i64> = vec![0, 1, 2];
        tensor_video_fft.fft_fftshift(/*dim =*/ dim)
    };

    let space_length: i64 = tensor_video_permuted.size()[2];
    let truncated_size: i64 = space_length >> 3;

    let compressed_fft: tch::Tensor = {
        let size_start: i64 = (space_length - truncated_size) >> 1;
        let size_end: i64 = size_start + truncated_size;

        tensor_video_fft.i(
            /*index =*/ (.., size_start..size_end, size_start..size_end, ..),
        )
    };

    let cat_fft: tch::Tensor = {
        let abs: tch::Tensor = compressed_fft.abs();
        let angle: tch::Tensor = compressed_fft.angle();
        tch::Tensor::cat(&[abs, angle], 0)
    };

    let input_for_interp: tch::Tensor = cat_fft.unsqueeze(0);

    let interpolated: tch::Tensor = input_for_interp.f_upsample_trilinear3d(
        /* output_size = */ &[truncated_size, truncated_size, 60 as i64],
        /* align_corners = */ false,
        /* scales_d = */ None,
        /* scales_h = */ None,
        /* scales_w = */ None,
    )?;

    return Ok(interpolated.squeeze());
}
