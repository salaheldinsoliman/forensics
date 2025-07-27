#!/usr/bin/env bash
# recover_with_scalpel.sh
# Uses a local scalpel.conf for reproducible config. Recovers files and generates manifest.
# Filters out DOCX files smaller than 8 KB in manifest.

set -euo pipefail

base_dir="$HOME/forensics"
image_dir="$base_dir/images"
output_dir="$base_dir/recovery_tools/scalpel"
manifest_dir="$output_dir"
local_conf="$base_dir/recovery_tools/scalpel/scalpel.conf"

if [[ ! -f "$local_conf" ]]; then
  echo "Missing scalpel.conf at $local_conf"
  exit 1
fi

# Always use our local config for this run
echo "Copying local scalpel.conf to /etc/scalpel/scalpel.conf"
sudo cp "$local_conf" /etc/scalpel/scalpel.conf

mkdir -p "$output_dir"

for size in 100MB 1GB 5GB; do
  size_lower="${size,,}"
  image_path="$image_dir/disk_${size}.img"
  recovery_path="$output_dir/$size_lower"
  manifest_path="$manifest_dir/manifest_${size_lower}.csv"

  echo "Processing $size_lower..."

  if [[ ! -f "$image_path" ]]; then
    echo "Skipping $size_lower (image not found)"
    continue
  fi

  # Clean previous recovery if exists
  rm -rf "$recovery_path"
  mkdir -p "$recovery_path"

  echo "Running scalpel..."
  scalpel -o "$recovery_path" -c /etc/scalpel/scalpel.conf "$image_path" > /dev/null

  # (Optional) delete docx smaller than 8K to save disk space:
  find "$recovery_path" -type f -name '*.docx' -size -8k -delete

  echo "Generating manifest: $manifest_path"
  echo "image,size,file_path,action,hash" > "$manifest_path"

  # Only include docx above 8K in manifest, but all others regardless of size
  find "$recovery_path" -type f | while read -r file; do
    rel_path="${file#$output_dir/}"
    if [[ "${file##*.}" == "docx" ]]; then
      size=$(stat -c "%s" "$file")
      if (( size < 8192 )); then
        continue
      fi
    fi
    hash=$(sha256sum "$file" | awk '{print $1}')
    echo "$image_path,$size_lower,$rel_path,unknown,$hash"
  done >> "$manifest_path"

done

echo "Scalpel recovery and manifest generation complete."
