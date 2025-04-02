#!/usr/bin/python3
from qwen_vl_utils import process_vision_info
from transformers import AutoProcessor
from transformers import AutoTokenizer
from transformers import Qwen2_5_VLForConditionalGeneration
import torch
import glob
import os


class infer_slave:
    def __init__(self, name_model=None):
        if name_model is None:
            name_model = NAME_MODEL
        self.name_model = name_model
        self.model = Qwen2_5_VLForConditionalGeneration.from_pretrained(
            self.name_model,
            torch_dtype=torch.bfloat16,
            attn_implementation="flash_attention_2",
            device_map="auto",
        )
        self.processor = AutoProcessor.from_pretrained(self.name_model)

    def infer_image(
        self,
        prompt_text_input,
        path_file_image_input,
        path_file_text_output,
    ):
        if os.path.exists(path_file_text_output):
            return False
        messages = [
            {
                "role": "user",
                "content": [
                    {
                        "type": "image",
                        "image": "file://" + path_file_image_input,
                    },
                    {"type": "text", "text": prompt_text_input},
                ],
            }
        ]
        text = self.processor.apply_chat_template(
            messages,
            tokenize=False,
            add_generation_prompt=True,
        )
        (
            image_inputs,
            video_inputs,
        ) = process_vision_info(
            messages,
        )
        inputs = self.processor(
            text=[text],
            images=image_inputs,
            videos=video_inputs,
            padding=True,
            return_tensors="pt",
        )
        inputs = inputs.to(device=self.model.device, dtype=torch.bfloat16)
        generated_ids = self.model.generate(**inputs, max_new_tokens=1280)
        generated_ids_trimmed = [
            out_ids[len(in_ids) :]
            for in_ids, out_ids in zip(
                inputs.input_ids,
                generated_ids,
            )
        ]
        output_text = self.processor.batch_decode(
            generated_ids_trimmed,
            skip_special_tokens=True,
            clean_up_tokenization_spaces=False,
        )
        open(
            path_file_text_output,
            "w",
            encoding="utf-8",
        ).write(output_text[0])
        return True

    def infer_video(
        self,
        prompt_text_input,
        path_file_video_input,
        path_file_text_output,
    ):
        if os.path.exists(path_file_text_output):
            return False
        messages = [
            {
                "role": "user",
                "content": [
                    {
                        "type": "video",
                        "video": "file://" + path_file_video_input,
                        "max_pixels": 360 * 420,
                        "fps": 2.0,
                    },
                    {"type": "text", "text": prompt_text_input},
                ],
            }
        ]
        text = self.processor.apply_chat_template(
            messages,
            tokenize=False,
            add_generation_prompt=True,
        )
        (
            image_inputs,
            video_inputs,
            video_kwargs,
        ) = process_vision_info(
            messages,
            return_video_kwargs=True,
        )
        inputs = self.processor(
            text=[text],
            images=image_inputs,
            videos=video_inputs,
            padding=True,
            return_tensors="pt",
            **video_kwargs,
        )
        inputs = inputs.to(device=self.model.device, dtype=torch.bfloat16)
        generated_ids = self.model.generate(**inputs, max_new_tokens=1280)
        generated_ids_trimmed = [
            out_ids[len(in_ids) :]
            for in_ids, out_ids in zip(
                inputs.input_ids,
                generated_ids,
            )
        ]
        output_text = self.processor.batch_decode(
            generated_ids_trimmed,
            skip_special_tokens=True,
            clean_up_tokenization_spaces=False,
        )
        open(
            path_file_text_output,
            "w",
            encoding="utf-8",
        ).write(output_text[0])
        return True


NAME_MODEL = "Qwen/Qwen2.5-VL-3B-Instruct"
slave = infer_slave()
prompt = """
There is a sick patient lying on the hospiral bed in this image, the beds have guard rails on the sides to prevent the patient from rolling over and falling by accident. Are the rails raised or lowered ? 
"""
print(prompt)
file_list = glob.glob("/data/input/mix_rails/*.jpg")
file_list.sort()
for i in file_list:
    print("inferring on " + i)
    j = i[0:-3] + "txt"
    slave.infer_image(
        prompt,
        i,
        j,
    )
    print("done inferring on " + i)
