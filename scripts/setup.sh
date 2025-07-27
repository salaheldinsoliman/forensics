#!/usr/bin/env bash
# setup.sh
# Orchestrates full environment prep for forensic experiments.

set -euo pipefail

base_dir="$HOME/forensics"
scripts_dir="$base_dir/scripts"

echo "=============================================="
echo "==        FORENSIC EXPERIMENT SETUP         =="
echo "=============================================="

echo
echo "[1/5] Preparing data directories..."
"$scripts_dir/prepare_dirs.sh"

echo
echo "[2/5] Creating disk images..."
"$scripts_dir/create_images.sh"

echo
echo "[3/5] Mounting disk images..."
"$scripts_dir/mount_images.sh"

echo
echo "[4/5] Generating original manifests..."
"$scripts_dir/generate_original_manifest.sh"

echo
echo "[5/5] Simulating deletion and corruption..."
"$scripts_dir/simulate_delete_corrupt.sh"

echo
echo "=============================================="
echo "||          SETUP COMPLETE!                ||"
echo "=============================================="
sleep 1
echo
cat <<'EOF'
 ______      _                _             
|  ____|    | |              | |            
| |__   ___ | | ___  ___  ___| |_ ___  _ __ 
|  __| / _ \| |/ _ \/ __|/ _ \ __/ _ \| '__|
| |___| (_) | |  __/\__ \  __/ || (_) | |   
|______\___/|_|\___||___/\___|\__\___/|_|   
                                            
EOF

echo "Next steps:"
echo "-----------"
echo "You can now run your recovery experiments:"
echo
echo "  1. Sleuth Kit:   ./recover_with_tsk.sh"
echo "  2. PhotoRec:     ./recover_with_photorec.sh"
echo "  3. Scalpel:      ./recover_with_scalpel.sh"
echo
echo "After recovery, compare manifests with:"
echo "  ./verify_recovery_result.sh <original> <simulated> <recovered>"
echo
echo "Check README.md for more details."
