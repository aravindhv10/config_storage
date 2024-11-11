#!/usr/bin/python3
import torch
from diffusers import FluxPipeline

pipe = FluxPipeline.from_pretrained(
    "black-forest-labs/FLUX.1-dev", device_map="balanced", torch_dtype=torch.bfloat16
)

pipe.transformer = torch.compile(pipe.transformer)


def do_infer(prompt, path_image_output, width=1360, height=768):
    out = pipe(
        prompt=prompt,
        guidance_scale=3.5,
        height=height,
        width=width,
        num_inference_steps=20,
    ).images[0]

    out.save(path_image_output)


prompt = "a tiny astronaut hatching from an egg on the moon"
do_infer(
    prompt=prompt, path_image_output="/data/output/image.png", width=1360, height=768
)
