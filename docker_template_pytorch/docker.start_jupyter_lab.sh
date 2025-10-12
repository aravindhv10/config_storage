#!/bin/sh
cd '/data/output'
. "${HOME}/venv/bin/activate"
'jupyter' 'notebook' 'password'
exec 'jupyter' 'lab' '--allow-root' '--ip=*'
