#!/bin/sh
cd "$(dirname -- "${0}")"
sed "s/#IP#/${1}/g ; s/#KEY#/${2}/g" './garage_headers.toml' > './garage.toml'
cat './garage_peers.toml' >> './garage.toml'
cat './garage_s3.toml' >> './garage.toml'
exit '0'
