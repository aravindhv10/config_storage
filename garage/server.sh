#!/bin/sh
cd "$(dirname -- "${0}")"
mkdir '-pv' -- './garage/'
/var/tmp/garage/bin/garage -c "$(realpath ./garage.toml)" server
