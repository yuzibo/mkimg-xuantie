#!/bin/bash

make_rootfs_tarball()
{
    # use $1
    PACKAGE_LIST="$KEYRINGS $GPU_DRIVER $BASE_TOOLS $GRAPHIC_TOOLS $XFCE_DESKTOP $BENCHMARK_TOOLS $FONTS $INCLUDE_APPS $EXTRA_TOOLS $LIBREOFFICE"
    mmdebstrap --architectures=riscv64 \
        --include="$PACKAGE_LIST" \
        sid $1 \
        "deb https://mirror.iscas.ac.cn/revyos/revyos-gles-21/ revyos-gles-21 main" \
        "deb https://mirror.iscas.ac.cn/revyos/revyos-addons/ revyos-addons main" \
        "deb https://mirror.iscas.ac.cn/revyos/revyos-kernels/ revyos-kernels main" \
        "deb https://mirror.iscas.ac.cn/revyos/revyos-base/ sid main contrib non-free non-free-firmware"
}

make_rootfs()
{
    if [[ -z "$USE_TARBALL" ]]; then
        echo "env USE_TARBALL is set to the empty string!"
        echo "create rootfs"
        make_rootfs_tarball $CHROOT_TARGET
    else
        tar xpvf $USE_TARBALL --xattrs-include='*.*' --numeric-owner -C $CHROOT_TARGET
        wget https://github.com/ruyisdk/ruyi/releases/download/0.31.0/ruyi-0.31.0.riscv64
        sudo mv ruyi-0.31.0.riscv64 $CHROOT_TARGET/usr/bin/ruyi
        sudo chmod 0755 $CHROOT_TARGET/usr/bin/ruyi
        sudo chown root:root $CHROOT_TARGET/usr/bin/ruyi
    fi

    # move /boot contents to other place
    if [ ! -z "$(ls -A "$CHROOT_TARGET"/boot/)" ]; then
        mkdir "$CHROOT_TARGET"/mnt/boot
        mv -v "$CHROOT_TARGET"/boot/* "$CHROOT_TARGET"/mnt/boot/
    fi

    # Mount chroot path
    mount "$BOOT_IMG" "$CHROOT_TARGET"/boot
    mount -t proc /proc "$CHROOT_TARGET"/proc
    mount -B /sys "$CHROOT_TARGET"/sys
    mount -B /run "$CHROOT_TARGET"/run
    mount -B /dev "$CHROOT_TARGET"/dev
    mount -B /dev/pts "$CHROOT_TARGET"/dev/pts
    mount -t tmpfs tmpfs "$CHROOT_TARGET"/tmp
    mount -t tmpfs tmpfs "$CHROOT_TARGET"/var/tmp
    mount -t tmpfs tmpfs "$CHROOT_TARGET"/var/cache/apt/archives/

    # move boot contents back to /boot
    if [ ! -z "$(ls -A "$CHROOT_TARGET"/mnt/boot/)" ]; then
        mv -v "$CHROOT_TARGET"/mnt/boot/* "$CHROOT_TARGET"/boot/
        rmdir "$CHROOT_TARGET"/mnt/boot
    fi

    # apt update
    chroot "$CHROOT_TARGET" /bin/bash << EOF
apt update
EOF
}
