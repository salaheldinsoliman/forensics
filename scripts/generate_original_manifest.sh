#!/usr/bin/env bash
# generate_original_manifest.sh
# Scans mounted image directories and creates a per-image manifest including hashes.

set -euo pipefail

base_dir="$HOME/forensics"
mnt_dir="$base_dir/mnt"
manifest_dir="$base_dir/manifests"

mkdir -p "$manifest_dir"

for size in 100MB 1GB 5GB; do
  mnt="$mnt_dir/mnt_${size}"
  image="disk_${size}.img"
  size_lower="${size,,}"
  outfile="$manifest_dir/manifest_${size_lower}.csv"

  echo "image,size,file_path,action,hash" > "$outfile"

  if mountpoint -q "$mnt"; then
    find "$mnt" -path "$mnt/lost+found" -prune -o -type f -print | while read -r file; do
      rel_path="/${file##$mnt/}"
      hash=$(sha256sum "$file" | awk '{print $1}')
      echo "$image,$size_lower,$rel_path,keep,$hash" >> "$outfile"
    done
  else
    echo "Warning: $mnt is not mounted. Skipping."
  fi
done

echo "Per-image manifests written to $manifest_dir as manifest_*.csv"
