#!/usr/bin/python3
from qwen_vl_utils import process_vision_info
from transformers import AutoProcessor
from transformers import AutoTokenizer
from transformers import Qwen2VLForConditionalGeneration
import os
import sys
import time
import torch


def remove_extension(path_input):
    loc = path_input.rfind(".")
    return path_input[0:loc]


def get_all_images(path_dir_input):
    ret = []

    for dirpath, dirnames, filenames in os.walk(path_dir_input):
        for filename in filenames:
            tmp = filename.lower()

            if tmp.endswith(".jpg") or tmp.endswith(".jpeg") or tmp.endswith(".png"):
                ret.append(os.path.join(dirpath, filename))

    return ret


def replace_base_dir(list_paths, path_input, path_output):
    res = list(path_output + i[len(path_input) :] for i in list_paths)
    return res


class infer_slave:
    def __init__(self, model_index=0):
        model_list = (
            "Qwen/Qwen2-VL-72B-Instruct-GPTQ-Int8",
            "Qwen/Qwen2-VL-7B-Instruct-GPTQ-Int8",
            "Qwen/Qwen2-VL-7B-Instruct-AWQ",
            "Qwen/Qwen2-VL-7B-Instruct",
        )

        self.model_name = model_list[model_index]

        self.model = Qwen2VLForConditionalGeneration.from_pretrained(
            self.model_name,
            torch_dtype=torch.bfloat16,
            attn_implementation="flash_attention_2",
            device_map="auto",
        )

        self.processor = AutoProcessor.from_pretrained(
            self.model_name,
        )

    def do_process(self, path_image_input, path_caption_input):
        messages = [
            {
                "role": "user",
                "content": [
                    {
                        "type": "image",
                        "image": path_image_input,
                    },
                    {
                        "type": "text",
                        "text": open(path_caption_input, "r", encoding="utf-8").read(),
                    },
                ],
            }
        ]

        # Preparation for inference
        text = self.processor.apply_chat_template(
            messages, tokenize=False, add_generation_prompt=True
        )

        image_inputs, video_inputs = process_vision_info(messages)

        inputs = self.processor(
            text=[text],
            images=image_inputs,
            videos=video_inputs,
            padding=True,
            return_tensors="pt",
        )

        inputs = inputs.to("cuda")
        return inputs

    def do_infer(self, path_image_input, path_caption_input):
        messages = [
            {
                "role": "user",
                "content": [
                    {
                        "type": "image",
                        "image": path_image_input,
                    },
                    {
                        "type": "text",
                        "text": open(path_caption_input, "r", encoding="utf-8").read(),
                    },
                ],
            }
        ]

        # Preparation for inference
        text = self.processor.apply_chat_template(
            messages, tokenize=False, add_generation_prompt=True
        )

        image_inputs, video_inputs = process_vision_info(messages)

        inputs = self.processor(
            text=[text],
            images=image_inputs,
            videos=video_inputs,
            padding=True,
            return_tensors="pt",
        )

        inputs = inputs.to("cuda")

        # Inference: Generation of the output
        generated_ids = self.model.generate(**inputs, max_new_tokens=1024)
        generated_ids_trimmed = [
            out_ids[len(in_ids) :]
            for in_ids, out_ids in zip(inputs.input_ids, generated_ids)
        ]
        output_text = self.processor.batch_decode(
            generated_ids_trimmed,
            skip_special_tokens=True,
            clean_up_tokenization_spaces=False,
        )

        os.unlink(path_image_input)
        os.unlink(path_caption_input)

        return output_text

    def do_docker_infer(self):
        list_path_images = get_all_images(path_dir_input="/data/input")
        list_path_images.sort()

        list_path_captions = list(
            remove_extension(path_input=i) + ".txt" for i in list_path_images
        )

        list_path_work = list(
            remove_extension(path_input=i) + ".work" for i in list_path_images
        )

        list_path_captions_output = replace_base_dir(
            list_paths=list_path_captions,
            path_input="/data/input",
            path_output="/data/output",
        )

        for i in range(len(list_path_images)):
            path_done = (
                remove_extension(path_input=list_path_captions_output[i]) + ".done"
            )

            if (
                os.path.exists(list_path_captions[i])
                and os.path.exists(list_path_work[i])
                and (not os.path.exists(path_done))
            ):
                if os.path.exists(list_path_captions_output[i]):
                    os.unlink(list_path_captions_output[i])

                res = self.do_infer(
                    path_image_input=list_path_images[i],
                    path_caption_input=list_path_captions[i],
                )[0]

                open(list_path_captions_output[i], "w", encoding="utf-8").write(res)

                os.unlink(list_path_work[i])

                open(path_done, "w").close()


slave = infer_slave()
slave.do_docker_infer()

while len(sys.argv) > 1:
    time.sleep(0.2)
    slave.do_docker_infer()
