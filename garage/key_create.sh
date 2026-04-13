#!/bin/sh
cd "$(dirname -- "${0}")"
/var/tmp/garage/bin/garage -c "$(realpath ./garage.toml)" key create mykey
