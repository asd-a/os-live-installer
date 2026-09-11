#!/bin/sh

set -e

label=$(cat $1)

cat <<EOF
root=live:LABEL=$label rd.live.image rw console=tty0 console=ttyS0,115200n8
EOF