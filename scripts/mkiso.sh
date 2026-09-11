#!/bin/sh

set -e

label=$(cat $2/label)
build_dir=$(realpath $2)

xorriso -as mkisofs \
    -o $3 \
    -V $label \
    -R \
    -J \
    -iso-level 3 \
    -eltorito-alt-boot \
    -e efiboot.img \
    -no-emul-boot \
    -isohybrid-gpt-basdat \
    $1