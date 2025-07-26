#!/usr/bin/env bash
# recover_with_tsk.sh
# Recovers files (including deleted) from disk images using Sleuth Kit
# and generates a hashed manifest for each image.

set -euo pipefail

base_dir="$HOME/forensics"
image_dir="$base_dir/images"
output_dir="$base_dir/recovery_tools/sleuthkit"

mkdir -p "$output_dir"

for size in 100MB 1GB 5GB; do
  size_lower="${size,,}"
  image_path="$image_dir/disk_${size}.img"
  recovery_path="$output_dir/$size_lower"
  manifest_path="$output_dir/manifest_${size_lower}.csv"

  echo "Processing $size_lower..."

  if [[ ! -f "$image_path" ]]; then
    echo "Skipping $size_lower (image not found)"
    continue
  fi

  # Clean previous recovery if it exists
  rm -rf "$recovery_path"
  mkdir -p "$recovery_path"

  echo "Recovering files from $image_path into $recovery_path..."
  tsk_recover -e "$image_path" "$recovery_path"

  echo "Generating manifest: $manifest_path"
  echo "image,size,file_path,action,hash" > "$manifest_path"

  while IFS= read -r -d '' file; do
    rel_path="${file#$recovery_path}"
    hash=$(sha256sum "$file" | cut -d ' ' -f 1)
    echo "$image_path,$size_lower,$rel_path,unknown,$hash"
  done < <(find "$recovery_path" -type f -print0) >> "$manifest_path"

done

echo "Recovery and manifest generation complete."
