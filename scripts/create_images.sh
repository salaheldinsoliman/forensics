#!/usr/bin/env bash
# regenerate_images.sh
# Recreates disk images based on real sizes of ~/forensics/data/* folders

set -euo pipefail

base_dir="$HOME/forensics"
data_dir="$base_dir/data"
image_dir="$base_dir/images"
mnt_base="/tmp/restore"

buffer_percent=10  # Extra space to account for ext4 overhead

mkdir -p "$image_dir"

for path in "$data_dir"/*; do
  [[ -d "$path" ]] || continue

  name=$(basename "$path")  # e.g., 100mb, 1gb, 5gb
  image_path="$image_dir/disk_${name^^}.img"
  mnt_path="$mnt_base/$name"

  # Get actual size of files (in MB), rounded up
  size_mb=$(du -sm "$path" | awk '{print $1}')
  buffer_mb=$(( size_mb * buffer_percent / 100 ))
  total_mb=$(( size_mb + buffer_mb + 10 ))  # +10MB safety net

  echo "Creating image for $name ($total_mb MB)..."
  dd if=/dev/zero of="$image_path" bs=1M count="$total_mb" status=none
  mkfs.ext4 -F "$image_path" > /dev/null

  echo "Mounting image..."
  sudo mkdir -p "$mnt_path"
  sudo mount -o loop "$image_path" "$mnt_path"

  echo "Copying files..."
  sudo cp -a "$path/." "$mnt_path/"

  echo "Unmounting..."
  sudo umount "$mnt_path"
done

echo "Images regenerated in $image_dir"
