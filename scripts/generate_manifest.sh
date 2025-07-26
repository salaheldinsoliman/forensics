#!/usr/bin/env bash
# generate_manifest.sh
# This script scans mounted image directories and creates a separate manifest per image.

set -euo pipefail

# Directories
base_dir="$HOME/forensics"
mnt_dir="$base_dir/mnt"
manifest_dir="$base_dir/manifests"

# Create manifest output directory
mkdir -p "$manifest_dir"

# Process each mounted image directory
for size in 100MB 1GB 5GB; do
  mnt="$mnt_dir/mnt_${size}"
  image="disk_${size}.img"
  size_lower="${size,,}"
  outfile="$manifest_dir/manifest_${size_lower}.csv"

  echo "image,size,file_path,action" > "$outfile"

  if mountpoint -q "$mnt"; then
    find "$mnt" -type f | while read file; do
      rel_path="/${file##$mnt/}"
      echo "$image,$size_lower,$rel_path,keep" >> "$outfile"
    done
  else
    echo "Warning: $mnt is not mounted. Skipping."
  fi

done

echo "Per-image manifests written to $manifest_dir as manifest_*.csv"
