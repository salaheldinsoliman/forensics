#!/usr/bin/env bash
# prepare_data_dirs.sh
# This script prepares data directories (100mb, 1gb, 5gb) under ./data/, each filled with sample files up to 95% of the target size.

set -euo pipefail

# Configuration
base_dir="$HOME/forensics"
sample_dir="$base_dir/samples"
data_dir="$base_dir/data"
declare -A targets=( [100mb]=95 [1gb]=950 [5gb]=4750 )  # in MB (95% of target sizes)

# Prepare data dir
rm -rf "$data_dir"
mkdir -p "$data_dir"

# Load sample files
mapfile -t sample_files < <(find "$sample_dir" -type f)
if [[ ${#sample_files[@]} -eq 0 ]]; then
  echo "No sample files found in $sample_dir. Aborting."
  exit 1
fi

# Create and fill each target directory
for key in "${!targets[@]}"; do
  echo "Creating $key directory and filling it to ~${targets[$key]}MB..."
  target_dir="$data_dir/$key"
  mkdir -p "$target_dir"

  used=0
  i=0
  target_bytes=$(( targets[$key] * 1024 * 1024 ))

  while (( used < target_bytes )); do
    for file in "${sample_files[@]}"; do
      base=$(basename "$file")
      cp "$file" "$target_dir/copy_${i}_$base"
      size=$(stat -c%s "$target_dir/copy_${i}_$base")
      used=$(( used + size ))
      i=$(( i + 1 ))
      if (( used >= target_bytes )); then
        break
      fi
    done
  done
  echo "$key filled to ~$((used / 1024 / 1024))MB"
done

echo "All data directories prepared under $data_dir"
