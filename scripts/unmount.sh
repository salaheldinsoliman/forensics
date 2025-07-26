#!/usr/bin/env bash
# unmount_images.sh
# This script unmounts all forensics disk images cleanly.

set -euo pipefail

# Base mount directory
mnt_dir="$HOME/forensics/mnt"

# === Unmount all mounted images ===
for size in 100MB 1GB 5GB; do
  mnt="$mnt_dir/mnt_${size}"

  if mountpoint -q "$mnt"; then
    echo "Unmounting $mnt..."
    sudo umount "$mnt"
  else
    echo "$mnt is not mounted."
  fi

  if [ -d "$mnt" ]; then
    rmdir "$mnt" || echo "Warning: failed to remove $mnt"
  fi

done

echo "✅ All mount points unmounted and cleaned up."
