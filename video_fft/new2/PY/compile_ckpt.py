#!/usr/bin/env python3
import sys
from litwrap import compile_model_to_aot_inductor


if __name__ == "__main__":
    compile_model_to_aot_inductor(
        path_file_input_lightning_ckpt=sys.argv[1],
        path_file_output_compiled_pt2=sys.argv[2],
        batch_size=2,
    )
