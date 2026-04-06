#!/bin/sh
cd "$('dirname' '--' "${0}")"
'/root/compile.py'
exec 'infer-server'
