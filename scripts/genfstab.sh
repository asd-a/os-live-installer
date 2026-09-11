#!/bin/sh

set -e

UUID_ROOT=$(findmnt -no UUID $1)
UUID_BOOT=$(findmnt -no UUID $1/boot/efi)

PATERN="%s\t%s\t%s\t%s\t%s\t%s"

BOOT=$(printf "$PATERN" "UUID=$UUID_BOOT" "/boot/efi" "vfat" "defaults,umask=027" "0" "2")
ROOT=$(printf "$PATERN" "UUID=$UUID_ROOT" "/" "ext4" "defaults" "0" "1")

FSTAB=$(printf "%s\n%s\n" "$BOOT" "$ROOT")

cat <<EOF
# /etc/fstab: static file system information.
#
# Use 'blkid' to print the universally unique identifier for a device;
# this may be used with UUID= as a more robust way to name devices that
# works even if disks are added and removed. See fstab(5).
#
# <file system>  <mount point>  <type>  <options>  <dump>  <pass>
$FSTAB
EOF
