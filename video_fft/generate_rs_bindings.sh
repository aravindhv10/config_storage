#!/bin/sh
cd "$(dirname -- "${0}")"
. './env.sh'
cd 'src'
bindgen './export.hpp' > './export.rs'
