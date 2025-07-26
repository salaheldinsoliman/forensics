#!/usr/bin/env bash
# mount_images.sh
# Mounts ext4 disk images for manual inspection or interaction.

set -euo pipefail

base_dir="$HOME/forensics"
image_dir="$base_dir/images"
mnt_dir="$base_dir/mnt"

echo "Mounting image files..."

for size in 100MB 1GB 5GB; do
  img="$image_dir/disk_${size}.img"
  mnt="$mnt_dir/mnt_${size}"

  mkdir -p "$mnt"

  echo "Mounting $img at $mnt..."
  if ! mount | grep -q "$mnt"; then
    sudo mount -o loop "$img" "$mnt"
  else
    echo "$img is already mounted at $mnt"
  fi
done

echo "All images have been mounted."
