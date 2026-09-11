#!/bin/bash

set -e

root_dir=$(realpath $1)

dnf \
    --installroot="$root_dir" \
    --repo="baseos,appstream,extras" \
    --releasever=$2 \
    --setopt=install_weak_deps=False \
    --nogpgcheck \
    -y install \
    dnf \
    coreutils \
    util-linux \
    rocky-release rocky-repos rocky-gpg-keys dnf \
    epel-release

# repo change to tuna or sjtu
sed -e 's|^mirrorlist=|#mirrorlist=|g' \
    -e 's|^#baseurl=http://dl.rockylinux.org/$contentdir|baseurl=https://mirror.sjtu.edu.cn/rocky|g' \
    -i.bak \
    $root_dir/etc/yum.repos.d/rocky*.repo

sed -e 's!^metalink=!#metalink=!g' \
    -e 's!^#baseurl=!baseurl=!g' \
    -e 's!https\?://download\.fedoraproject\.org/pub/epel!https://mirrors.tuna.tsinghua.edu.cn/epel!g' \
    -e 's!https\?://download\.example/pub/epel!https://mirrors.tuna.tsinghua.edu.cn/epel!g' \
    -i.bak \
    $root_dir/etc/yum.repos.d/epel{,-testing}.repo


touch $root_dir/etc/resolv.conf