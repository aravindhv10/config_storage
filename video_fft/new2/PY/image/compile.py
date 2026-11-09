#!/usr/bin/env python3
import sys
from main import compile_to_aot_inductor


compile_to_aot_inductor(
    path_file_ckpt=sys.argv[1],
    path_file_pt2_output=sys.argv[2],
)
