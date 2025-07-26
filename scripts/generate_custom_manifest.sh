#!/usr/bin/env bash
# generate_manifest_custom.sh
# Usage: generate_manifest_custom.sh <input_dir> <output_csv>
# This script scans a given directory and writes a manifest with file paths and hashes.

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <input_dir> <output_csv>"
  exit 1
fi

input_dir="$1"
outfile="$2"

# Write CSV header
echo "image,size,file_path,action,hash" > "$outfile"

# Use N/A for image and size since this is a general-purpose manifest
echo "Scanning files in $input_dir..."
find "$input_dir" -type f | while read -r file; do
  rel_path="/${file##$input_dir/}"
  hash=$(sha256sum "$file" | awk '{print $1}')
  echo "N/A,N/A,$rel_path,keep,$hash" >> "$outfile"
done

echo "Manifest written to $outfile"
