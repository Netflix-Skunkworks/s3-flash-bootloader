#!/bin/bash
set -x
set -o errexit
set -o nounset
set -o pipefail

export DEBIAN_FRONTEND=noninteractive
readonly INITRD_DIR=initrd
readonly KERNEL_VERSION="4.18.0-25-generic"

base() {
    debootstrap \
        --include "openssh-server less vim-tiny iproute2 kmod udev ca-certificates systemd-sysv" \
        --variant=minbase \
        bionic "${INITRD_DIR}"

    cd "${INITRD_DIR}"
cat << EOF > etc/apt/sources.list
deb http://archive.ubuntu.com/ubuntu bionic main universe
deb http://archive.ubuntu.com/ubuntu bionic-security main universe
EOF

    chroot . /root/kernel.sh "${KERNEL_VERSION}"
    cp boot/vmlinuz* ../vmlinuz

    rm -rf -- \
       boot/vmlinuz* \
       etc/ssh/ssh_host_*_key* \
       etc/hostname \
       etc/machine-id \
       root/* \
       usr/share/doc \
       usr/share/i18n \
       usr/share/locale \
       var/cache/apt \
       var/lib/dpkg/info \
       var/lib/apt \
       var/log

    mkdir var/lib/dpkg/info

    cd ..
}

installer() {
  cd "${INITRD_DIR}"

  ln -s /sbin/init init

  touch root/watchdoge.lock
  chmod +x usr/local/bin/install_from_s3
  ln -s install_from_s3 usr/local/bin/watchdoge

  find . -print0 | cpio -o -H newc -R 0:0 --null | gzip > ../initrd.gz
  cd ..
  rm -r "${INITRD_DIR}"
}

apt update
apt-get install -y debootstrap liblz4-tool curl cpio
rm -rf build
cp -r src build
cd build
base
installer
tar cvfz bootloader-$(uname -m).tar.gz *
