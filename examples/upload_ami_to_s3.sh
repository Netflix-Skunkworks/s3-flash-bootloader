#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

if [[ -z ${2:-} ]]; then
  cat >&2 <<EOF
Usage: $0 <ami id> <s3 url>
  Copies an EBS-backed AMI image to S3 as an lz4-compressed blob
EOF
  exit 1
fi

readonly ami_id="$1"
shift
readonly s3_url="$1"

readonly device_name="/dev/xvdg"

cat >&2 <<EOF
This script is recommended for use as a proof-of-concept only. It has not been
used in production environments.
 * it makes numerous assumptions about your environment
 * it requires IAM permissions to create and manage volumes
 * it can and will leak resources

EOF

set -x

# Find the snapshot id
readonly snapshot_id=$(
  aws ec2 describe-images --image-id "${ami_id}" |\
  jq -r '.Images[].BlockDeviceMappings[].Ebs["SnapshotId"] | values'
)

# Create the volume
readonly volume_id=$(
  aws ec2 create-volume --availability-zone $EC2_AVAILABILITY_ZONE \
    --snapshot-id ${snapshot_id} | jq -r '.["VolumeId"]'
)
aws ec2 wait volume-available --volume-ids "${volume_id}"
aws ec2 attach-volume --device "${device_name}" --volume-id "${volume_id}" \
  --instance-id "${EC2_INSTANCE_ID}"

while [[ ! -e "${device_name}" ]]; do
  sleep 0.5
done

# Copy to s3
lz4 -c "${device_name}" | aws s3 cp - "${s3_url}"

# Clean up
aws ec2 detach-volume --volume-id "${volume_id}"
aws ec2 wait volume-available --volume-id "${volume_id}"
aws ec2 delete-volume --volume-id "${volume_id}"
