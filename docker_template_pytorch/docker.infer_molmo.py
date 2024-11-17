#!/usr/bin/python3
from PIL import Image
from transformers import AutoModelForCausalLM
from transformers import AutoProcessor
from transformers import GenerationConfig
import requests
import torch


class image_loader:
    def __init__(self, path_file_image_input):
        self.o1_image = Image.open(path_file_image_input)


class molmo_model:
    def __init__(self):
        all_models = (
            "allenai/Molmo-72B-0924",
            "allenai/Molmo-7B-D-0924",
            "allenai/Molmo-7B-O-0924",
        )
        self.processor = AutoProcessor.from_pretrained(
            all_models[1],
            # "allenai/Molmo-72B-0924",
            trust_remote_code=True,
            torch_dtype="auto",
            device_map="auto",
        )

        self.model = AutoModelForCausalLM.from_pretrained(
            "allenai/Molmo-7B-D-0924",
            # "allenai/Molmo-72B-0924",
            trust_remote_code=True,
            torch_dtype="auto",
            device_map="auto",
        )

    def infer(self, image_PIL):
        # process the image and text
        inputs = self.processor.process(
            images=image_PIL,
            text="Describe this image in full detail.",
        )

        # move inputs to the correct device and make a batch of size 1
        inputs = {k: v.to(self.model.device).unsqueeze(0) for k, v in inputs.items()}

        # generate output; maximum 200 new tokens; stop generation when <|endoftext|> is generated
        output = self.model.generate_from_batch(
            inputs,
            GenerationConfig(max_new_tokens=200, stop_strings="<|endoftext|>"),
            tokenizer=self.processor.tokenizer,
        )

        # only get generated tokens; decode them to text
        generated_tokens = output[0, inputs["input_ids"].size(1) :]
        generated_text = self.processor.tokenizer.decode(
            generated_tokens, skip_special_tokens=True
        )

        # print the generated text
        print(generated_text)

        # >>> This image features an adorable black Labrador puppy sitting on a wooden deck.
        #     The puppy is positioned in the center of the frame, looking up at the camera...


image = image_loader("/data/input/image.png")
main_model = molmo_model()
main_model.infer(image.o1_image)
