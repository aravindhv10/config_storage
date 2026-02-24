#!/bin/sh
cd "$(dirname -- "${0}")"
rsync -avh --progress './nixos/' '/etc/nixos/'
