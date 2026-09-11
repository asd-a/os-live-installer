## intro

用于构建安装 Rocky SCC Linux 的 live cd iso，以及构建脚本

### Live CD

在 Rocky 系统上（最好大于等于 rocky 9）使用 root 权限执行：
```
make utils/mkiso
```
在 `build` 文件夹中生成可以直接 efi 启动的 `ROCKY_SCC_YYYY-MM-DD.iso`

### 安装系统

PS: 需要有至少 4G 的内存

进入 Live OS 系统后，登录 root 用户。执行：
```
cp -ra /run/initramfs/live/data /dev/shm/os-install
cd /dev/shm/os-install
```

在 `/dev/shm/os-install` 目录下即为本构建脚本项目（包含一些方便离线构建的中间产物）

目前是 root on ext4 的，后续应该会有更多选项

执行下面命令，即可开始安装系统
```
make utils/mksys DISK=/dev/sdX
```

如果需要手动配置可以
```
make utils/mount DISK=/dev/sdX

./scripts/chroot -r tmp/mnt

# then do something

make utils/umount
```

### TODO
 - [] 简要 locale + tzdata 配置
 - [] 网络配置
 - [] nvidia 驱动
 - [] root on zfs / other fs
 - [] 更多交互