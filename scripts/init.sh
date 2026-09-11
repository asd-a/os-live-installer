#!/bin/bash

set -e

root_dir=$(realpath $1)

dnf \
    --installroot="$root_dir" \
    --repo="baseos,appstream,epel" \
    --releasever=$2 \
    --setopt=install_weak_deps=False \
    --setopt=keepcache=False \
    --nogpgcheck \
    -y install \
    dnf \
    "dnf-command(config-manager)" \
    coreutils \
    util-linux \
    rocky-release rocky-repos rocky-gpg-keys \
    epel-release \
    https://zfsonlinux.org/epel/zfs-release-3-0.el$2.noarch.rpm \
    https://www.elrepo.org/elrepo-release-$2.el$2.elrepo.noarch.rpm

# repo change to tuna or sjtu
sed -e 's|^mirrorlist=|#mirrorlist=|g' \
    -e 's|^#baseurl=http://dl.rockylinux.org/$contentdir|baseurl=https://mirror.sjtu.edu.cn/rocky|g' \
    -i.bak \
    $root_dir/etc/yum.repos.d/rocky*.repo

sed -e 's|^mirrorlist=|#mirrorlist=|g' \
    -e 's|^baseurl=http://elrepo.org/linux|baseurl=https://mirrors.tuna.tsinghua.edu.cn/elrepo|g' \
    -i.bak \
    $root_dir/etc/yum.repos.d/elrepo.repo

sed -e 's!^metalink=!#metalink=!g' \
    -e 's!^#baseurl=!baseurl=!g' \
    -e 's!https\?://download\.fedoraproject\.org/pub/epel!https://mirrors.tuna.tsinghua.edu.cn/epel!g' \
    -e 's!https\?://download\.example/pub/epel!https://mirrors.tuna.tsinghua.edu.cn/epel!g' \
    -i.bak \
    $root_dir/etc/yum.repos.d/epel{,-testing}.repo

touch $root_dir/etc/resolv.conf