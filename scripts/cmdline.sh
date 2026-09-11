#!/bin/sh

set -e

UUID_ROOT=$(findmnt -no UUID $1)

cat <<EOF
root=UUID=$UUID_ROOT rw console=tty0 console=ttyS0,115200n8 iommu=pt
EOF