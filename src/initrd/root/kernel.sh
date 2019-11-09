#!/bin/bash
set -x
set -o errexit
set -o nounset
set -o pipefail

KERNEL_VERSION="${1}"

cd /root
apt-get update
apt-get install --no-install-recommends -y liblz4-tool awscli curl "linux-modules-${KERNEL_VERSION}"
apt-get download "linux-image-${KERNEL_VERSION}"
dpkg -x *.deb /
depmod "${KERNEL_VERSION}"
systemctl enable systemd-networkd.service
systemctl enable systemd-resolved.service
systemctl enable systemd-networkd-wait-online.service
rm -r /etc/systemd/system/getty.target.wants
sed -ie 's/^root:\*:/root::/' /etc/shadow
