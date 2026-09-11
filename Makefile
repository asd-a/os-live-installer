ROCKY_VER ?= 9

default: clean-tmp

clean-tmp: 
	${MAKE} utils/umount
	umount -R tmp/bootstrap/* || true
	umount -R tmp/rootfs/* || true
	umount -R tmp/live-os/* || true
	rm -rf tmp

clean:
	${MAKE} clean-tmp
	rm -rf build

utils/mount:
	@test "${DISK}" != "" || (echo "Specify DISK=/dev/..."; exit 1)

	mkdir -p tmp/mnt
	mount `lsblk -nlo PATH ${DISK} | awk 'NR==3 {print}'` tmp/mnt

	mkdir -p tmp/mnt/boot/efi
	mount -o fmask=027,umask=027 `lsblk -nlo PATH ${DISK} | awk 'NR==2 {print}'` tmp/mnt/boot/efi

utils/umount:
	umount tmp/mnt/boot/efi 	|| true
	umount tmp/mnt 		|| true

DNF=dnf -y \
	--setopt=install_weak_deps=False \
	--setopt=keepcache=False

utils/bootstrap:
	mkdir -p tmp/rootfs
	mkdir -p tmp/bootstrap/rootfs
	
	mount --bind tmp/rootfs tmp/bootstrap/rootfs

	./scripts/bootstrap.sh tmp/bootstrap ${ROCKY_VER}

	cp ./scripts/init.sh tmp/bootstrap

	./scripts/chroot.sh tmp/bootstrap /init.sh /rootfs ${ROCKY_VER}

	umount tmp/bootstrap/rootfs

	rm -rf tmp/bootstrap

build/rootfs.tar.xz: packages/basic.txt packages/kernel.txt $(shell find ./common -type f)
	mkdir -p build

	${MAKE} utils/bootstrap

	@echo "Build Rocky rootfs into tmp/rootfs"

	./scripts/chroot.sh tmp/rootfs \
	${DNF} config-manager --set-enable elrepo-kernel

	./scripts/chroot.sh tmp/rootfs \
	${DNF} makecache

	./scripts/chroot.sh tmp/rootfs \
	${DNF} update

	./scripts/chroot.sh tmp/rootfs \
	${DNF} install `./scripts/packages.sh ./packages/basic.txt`

	./scripts/chroot.sh tmp/rootfs \
	${DNF} install `./scripts/packages.sh ./packages/kernel.txt`

	./scripts/chroot.sh -r tmp/rootfs rm /etc/machine-id
	
	./scripts/chroot.sh -r tmp/rootfs cp -a /etc/skel/. /root/

	cat ./common/passwd.txt | ./scripts/chroot.sh -r tmp/rootfs chpasswd -e
	
	./scripts/chroot.sh -r tmp/rootfs ln -sf ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

	cat ./common/ssh_keys.txt | ./scripts/chroot.sh -r tmp/rootfs tee /root/.ssh/authorized_keys
	./scripts/chroot.sh -r tmp/rootfs ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519 -N "" -C "scc"
	cat tmp/rootfs/root/.ssh/id_ed25519.pub | ./scripts/chroot.sh -r tmp/rootfs tee -a /root/.ssh/authorized_keys

	./scripts/chroot.sh -r tmp/rootfs systemctl enable sshd systemd-networkd systemd-resolved

	cp -r ./common/etc/. tmp/rootfs/etc/

	tar -C tmp/rootfs --xattrs --acls -capf $@.tmp .

	rm -rf tmp/rootfs

	mv $@.tmp $@

utils/format-efi:
	@test "${PART_EFI}" != "" || (echo "Specify PART_EFI"; exit 1)

	@echo format ${PART_EFI} as FAT
	mkfs.fat -F32 ${PART_EFI}

utils/format-root:
	@test "${PART_ROOT}" != "" || (echo "Specify PART_ROOT"; exit 1)

	@echo format ${PART_ROOT} as ext4
	mkfs.ext4 -F ${PART_ROOT}

build/label:
	mkdir -p build
	./scripts/label.sh > $@

utils/mkrootfs: build/rootfs.tar.xz

build/%.iso: build/label build/rootfs.tar.xz packages/live-os.txt
	mkdir -p tmp/iso/LiveOS/
	mkdir -p tmp/live-os/boot/efi

	rsync -rva --exclude="/tmp" --exclude="/.git" --exclude="/build/*.iso" ./ tmp/iso/data/
	
	truncate -s 256M tmp/iso/efiboot.img
	mkfs.fat -F32 tmp/iso/efiboot.img
	mount -o loop,fmask=027,umask=027 tmp/iso/efiboot.img tmp/live-os/boot/efi
	
	@echo "Bootstrapping Debian into tmp/live-os"
	tar --xattrs --acls -xapf build/rootfs.tar.xz -C tmp/live-os

	./scripts/chroot.sh -r tmp/live-os systemd-machine-id-setup
	./scripts/chroot.sh -r tmp/live-os systemd-machine-id-setup --commit

	./scripts/liveos-cmdline.sh build/label > tmp/live-os/etc/kernel/cmdline

	./scripts/chroot.sh -r tmp/live-os \
	${DNF} install `./scripts/packages.sh ./packages/live-os.txt`

	cp -r ./livecd/etc/. tmp/live-os/etc/

	./scripts/chroot.sh -r tmp/live-os bootctl install --no-variables
	./scripts/chroot.sh -r tmp/live-os /bin/bash -c "`cat ./scripts/kernel-add-all.sh`"

	umount tmp/live-os/boot/efi

	mksquashfs tmp/live-os tmp/iso/LiveOS/squashfs.img -comp zstd -noappend

	rm -rf tmp/live-os

	./scripts/mkiso.sh tmp/iso build $@.tmp

	rm -rf tmp/iso

	mv $@.tmp $@

utils/mkiso: build/label
	${MAKE} build/`cat build/label`.iso

utils/mksys:
	@test "${DISK}" != "" || (echo "Specify DISK=/dev/..."; exit 1)
	@read -p "Partition ${DISK}? (y/N): " c && [ "$$c" = y ] || { echo "Canceled"; exit 1; }

	sgdisk -Z "${DISK}"
	sgdisk -o "${DISK}"
	sgdisk -n 1:0:+1G -t 1:EF00 -c 1:"EFI System" "${DISK}"
	sgdisk -n 2:0:0 -t 2:8300 -c 2:"Rocky Linux (ext4)" "${DISK}"
	partprobe "${DISK}"

	${MAKE} utils/format-root "PART_ROOT=`lsblk -nlo PATH ${DISK} | awk 'NR==3 {print}'`"
	${MAKE} utils/format-efi  "PART_EFI=`lsblk -nlo PATH ${DISK} | awk 'NR==2 {print}'`"

	@echo "Bootstrapping Debian into tmp/mnt"
	
	${MAKE} utils/mount

	tar --xattrs --acls -xapf build/rootfs.tar.xz -C tmp/mnt

	./scripts/chroot.sh -r tmp/mnt systemd-machine-id-setup
	./scripts/chroot.sh -r tmp/mnt systemd-machine-id-setup --commit

	./scripts/cmdline.sh tmp/mnt > tmp/mnt/etc/kernel/cmdline
	./scripts/genfstab.sh tmp/mnt > tmp/mnt/etc/fstab
	
	./scripts/chroot.sh -r tmp/mnt bootctl install --no-variables
	./scripts/chroot.sh -r tmp/mnt /bin/bash -c "`cat ./scripts/kernel-add-all.sh`"
	
	${MAKE} utils/umount
