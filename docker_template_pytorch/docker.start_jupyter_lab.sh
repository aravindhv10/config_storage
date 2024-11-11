#!/bin/sh
cd '/data/output'
. "${HOME}/venv/bin/activate"
exec 'jupyter' 'lab' '--allow-root' '--ip=0.0.0.0'
