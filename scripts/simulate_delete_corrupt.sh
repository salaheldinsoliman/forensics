#!/usr/bin/env bash
# simulate_deletion_and_corruption.sh
# Randomly deletes and corrupts files in mounted images and generates hashed simulated manifests.
# Prints used disk space before and after modifications.

set -euo pipefail

base_dir="$HOME/forensics"
mnt_dir="$base_dir/mnt"
manifest_dir="$base_dir/manifests"
temp_manifest_dir="$base_dir/manifests_simulated"

# Settings
DELETE_PERCENT=20
CORRUPT_PERCENT=10

# Create directory for modified manifests
mkdir -p "$temp_manifest_dir"

for size in 100MB 1GB 5GB; do
  mnt="$mnt_dir/mnt_${size}"
  size_lower="${size,,}"
  orig_manifest="$manifest_dir/manifest_${size_lower}.csv"
  temp_manifest="$temp_manifest_dir/manifest_${size_lower}.csv"

  echo "Processing $size_lower..."

  # Skip if not mounted or manifest missing
  if ! mountpoint -q "$mnt" || [[ ! -f "$orig_manifest" ]]; then
    echo "Skipping $size_lower (not mounted or manifest missing)"
    continue
  fi

  echo "Used space before: $(sudo du -sh "$mnt" | cut -f1)"

  # Copy manifest to simulate modifications
  cp "$orig_manifest" "$temp_manifest"

  # Read all file paths from manifest with action=keep
  mapfile -t files < <(awk -F, '$4 == "keep" { print $3 }' "$orig_manifest")
  total=${#files[@]}

  # Calculate counts
  delete_count=$((total * DELETE_PERCENT / 100))
  corrupt_count=$((total * CORRUPT_PERCENT / 100))

  # Shuffle and select files
  shuffled=( $(printf "%s\n" "${files[@]}" | shuf) )
  to_delete=("${shuffled[@]:0:$delete_count}")
  to_corrupt=("${shuffled[@]:$delete_count:$corrupt_count}")

  # Delete files
  for path in "${to_delete[@]}"; do
    full_path="$mnt$path"
    if [[ -f "$full_path" ]]; then
      sudo rm -f "$full_path"
      sed -i "s|$path,keep|$path,deleted|" "$temp_manifest"
    fi
  done

  # Corrupt files (overwrite first 512 bytes)
  for path in "${to_corrupt[@]}"; do
    full_path="$mnt$path"
    if [[ -f "$full_path" ]]; then
      sudo dd if=/dev/zero of="$full_path" bs=512 count=1 conv=notrunc status=none
      sed -i "s|$path,keep|$path,corrupted|" "$temp_manifest"
    fi
  done

  # Recompute hashes
  echo "image,size,file_path,action,hash" > "$temp_manifest.tmp"
  while IFS=, read -r image size path action _; do
    full_path="$mnt$path"
    if [[ "$path" == "file_path" ]]; then continue; fi

    if [[ -f "$full_path" ]]; then
      hash=$(sha256sum "$full_path" | cut -d ' ' -f 1)
    else
      hash=""
    fi
    echo "$image,$size,$path,$action,$hash" >> "$temp_manifest.tmp"
  done < "$temp_manifest"

  mv "$temp_manifest.tmp" "$temp_manifest"

  echo "Used space after:  $(sudo du -sh "$mnt" | cut -f1)"
  echo ""
done

echo "Done simulating deletions and corruption. Hashed manifests written to $temp_manifest_dir"
