#!/bin/sh
cd "$('dirname' -- "${0}")"
buildah build --tag nixbuilder .
