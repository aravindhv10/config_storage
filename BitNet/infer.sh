#!/bin/sh
cd "$('dirname' '--' "${0}")"
. './venv/bin/activate'
'python3' './infer.py'
