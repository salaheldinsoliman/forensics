#!/usr/bin/env bash
# Runs PhotoRec interactively or using .cmd (if needed)

set -euo pipefail

loopdev=$(losetup | grep disk_100MB.img | awk '{print $1}')
outdir="$HOME/forensics/recovery_tools/photorec/recovered/100MB"

mkdir -p "$outdir"

echo "Running PhotoRec on $loopdev..."
sudo photorec "$loopdev"
