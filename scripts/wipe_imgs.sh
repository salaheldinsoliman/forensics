#!/usr/bin/env bash
# wipe_images.sh
# Mounts each ext4 image and deletes its contents

set -euo pipefail

base_dir="$HOME/forensics"
image_dir="$base_dir/images"
mnt_dir="$base_dir/mnt"

for size in 100MB 1GB 5GB; do
  img="$image_dir/disk_${size}.img"
  mnt="$mnt_dir/mnt_${size}"

  echo "Mounting $img..."
  mkdir -p "$mnt"
  if ! mount | grep -q "$mnt"; then
    sudo mount -o loop "$img" "$mnt"
  fi

  echo "Deleting contents of $mnt..."
  sudo rm -rf "$mnt"/*

  echo "$img wiped clean."
  sudo umount "$mnt"
  rmdir "$mnt"
done

echo "All images have been cleaned and unmounted."
