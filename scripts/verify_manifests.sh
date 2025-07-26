#!/usr/bin/env bash
# verify_manifest_changes.sh
# Compares two given manifest CSVs: original and a result (e.g., after recovery or simulation)

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <original_manifest.csv> <result_manifest.csv>"
  exit 1
fi

orig="$1"
sim="$2"

if [[ ! -f "$orig" || ! -f "$sim" ]]; then
  echo "Error: one or both manifest files do not exist."
  exit 1
fi

awk -F, -v orig="$orig" '
  BEGIN {
    deleted = 0; corrupted = 0; total = 0;

    while ((getline < orig) > 0) {
      if (NR == 1) continue;
      orig_map[$3] = $4;
      total++;
    }
    close(orig);
  }
  NR > 1 {
    path = $3;
    new_action = $4;
    orig_action = orig_map[path];

    if (orig_action == "keep" && new_action == "deleted") deleted++;
    else if (orig_action == "keep" && new_action == "corrupted") corrupted++;
  }
  END {
    dp = (deleted / total) * 100;
    cp = (corrupted / total) * 100;
    printf "Comparison Results:\nDeleted = %d (%.1f%%)\nCorrupted = %d (%.1f%%)\nTotal files = %d\n",
           deleted, dp, corrupted, cp, total;
  }
' "$sim"
