#!/bin/sh

for dir in /usr/lib/modules/*; do
    [ -d "$dir" ] || continue;
    kver=${dir##*/};
    echo "==> kernel-install add $kver";
    kernel-install add "$kver" "$dir/vmlinuz";
done