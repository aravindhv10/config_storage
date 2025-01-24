#!/bin/sh
cd "$(dirname -- "${0}")"
CARGO_HOME="${HOME}/.cargo"
mkdir -pv -- "${CARGO_HOME}"
cp -vf -- './config.toml' "${CARGO_HOME}/config.toml"
