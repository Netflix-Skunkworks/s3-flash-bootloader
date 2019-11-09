#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

if [[ -z ${2:-} ]]; then
  cat >&2 << EOF
Usage: $0 <s3 bucket/key> <root device>
  Configures the in-memory OS to flash the specified S3 key onto the specified
  root device
EOF
fi

s3_image="$1"
shift
root_device="$1"

sed -ie "s#root=.*#root=${root_device} source=${s3_image}#" /boot/grub/grub.cfg
