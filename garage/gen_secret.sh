#!/bin/sh
cd "$(dirname -- "${0}")"
sha512sum './secret.txt' | cut -b 1-64
