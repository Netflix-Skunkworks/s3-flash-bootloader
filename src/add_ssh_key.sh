#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

if [[ -z "${1:-}" || ! -e initrd.gz ]]; then
  cat >&2 <<EOF
Usage: $0 <ssh authorized keys file>
  run this script in the same directory as the initrd.gz you would like to modify
EOF
  exit 1
fi

readonly initrd_dir="${PWD}"
readonly source_file="${1}"
readonly authkeys="root/.ssh/authorized_keys"

TEMPDIR=$(mktemp -d)
mkdir -p "${TEMPDIR}/root/.ssh"
cp "${source_file}" "${TEMPDIR}/${authkeys}"
cd "${TEMPDIR}"

# Be careful not to include / in the new archive
# If one does, systemd-networkd will not come up, due to a permission issue.
find ./* -print0 | cpio -o -H newc -R 0:0 --null 2>/dev/null | gzip >> "${initrd_dir}/initrd.gz"
rm -rf "${TEMPDIR}"
