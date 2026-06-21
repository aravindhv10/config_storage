#!/bin/sh
cd "$('dirname' '--' "${0}")"
export RUST_LOG='info'
exec 'infer-server'
