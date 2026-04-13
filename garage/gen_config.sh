#!/bin/sh
cd "$(dirname -- "${0}")"
sed "s/#IP#/${1}/g" './garage_template.toml' > './garage.toml'
exit '0'
