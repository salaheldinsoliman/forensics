#!/usr/bin/env bash
# verify_recovery_result.sh
# Compares original, simulated, and recovered manifests using file content hashes.
# Reports recovery metrics and lists recovered deleted/corrupted files.

set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <original_manifest.csv> <simulated_manifest.csv> <recovered_manifest.csv>"
  exit 1
fi

orig="$1"
sim="$2"
recovered="$3"

for f in "$orig" "$sim" "$recovered"; do
  if [[ ! -f "$f" ]]; then
    echo "Error: missing file $f"
    exit 1
  fi
done

recovered_dir="$(dirname "$recovered")"
results_file="$recovered_dir/results.txt"
deleted_hits_file="$recovered_dir/recovered_from_deleted.txt"
corrupted_hits_file="$recovered_dir/recovered_from_corrupted.txt"

awk -F, -v sim_file="$sim" -v rec_file="$recovered" -v orig_file="$orig" \
    -v out="$results_file" -v deleted_out="$deleted_hits_file" -v corrupted_out="$corrupted_hits_file" '
  BEGIN {
    # Initialize counters
    orig_total = 0; orig_recovered = 0;
    keep_total = 0; deleted_total = 0; corrupted_total = 0;
    keep_rec = 0; deleted_rec = 0; corrupted_rec = 0;
  }

  # Load recovered file hashes and paths
  FNR == NR {
    if (FNR == 1) next;
    recovered_hashes[$5] = $3;  # hash -> path
    next;
  }

  # Process simulated manifest to build sets of interest
  FILENAME == sim_file {
    if (FNR == 1) next;
    hash = $5;
    action = $4;

    if (action == "keep") {
      keep_total++;
      if (hash in recovered_hashes) keep_rec++;
    } else if (action == "deleted") {
      deleted_total++;
      if (hash in recovered_hashes) {
        deleted_rec++;
        deleted_found[hash] = 1;
      }
    } else if (action == "corrupted") {
      corrupted_total++;
      if (hash in recovered_hashes) {
        corrupted_rec++;
        corrupted_found[hash] = 1;
      }
    }
    next;
  }

  # Count original total and recovery
  FILENAME == orig_file {
    if (FNR == 1) next;
    hash = $5;
    orig_total++;
    if (hash in recovered_hashes) orig_recovered++;
  }

  END {
    total_simulated = keep_total + deleted_total + corrupted_total;
    total_recovered = keep_rec + deleted_rec + corrupted_rec;

    o_pct = (orig_total > 0) ? (orig_recovered / orig_total) * 100 : 0;
    k_pct = (keep_total > 0) ? (keep_rec / keep_total) * 100 : 0;
    d_pct = (deleted_total > 0) ? (deleted_rec / deleted_total) * 100 : 0;
    c_pct = (corrupted_total > 0) ? (corrupted_rec / corrupted_total) * 100 : 0;
    sim_pct = (total_simulated > 0) ? (total_recovered / total_simulated) * 100 : 0;

    print "📊 Recovery Metrics Summary:";
    print "----------------------------";
    printf "Original total files         : %d\n", orig_total;
    printf "Simulated (keep/deleted/corrupted): %d / %d / %d\n", keep_total, deleted_total, corrupted_total;
    print "";
    printf "Recovered from keep          : %d of %d (%.1f%%)\n", keep_rec, keep_total, k_pct;
    printf "Recovered from deleted       : %d of %d (%.1f%%)\n", deleted_rec, deleted_total, d_pct;
    printf "Recovered from corrupted     : %d of %d (%.1f%%)\n", corrupted_rec, corrupted_total, c_pct;
    print "";
    printf "Total recovered from simulated: %d of %d (%.1f%%)\n", total_recovered, total_simulated, sim_pct;
    printf "Total recovered from original : %d of %d (%.1f%%)\n", orig_recovered, orig_total, o_pct;

    print "\nSaving to " out;

    print "Recovery Metrics Summary:\n----------------------------" > out;
    printf "Original total files         : %d\n", orig_total >> out;
    printf "Simulated (keep/deleted/corrupted): %d / %d / %d\n", keep_total, deleted_total, corrupted_total >> out;
    print "" >> out;
    printf "Recovered from keep          : %d of %d (%.1f%%)\n", keep_rec, keep_total, k_pct >> out;
    printf "Recovered from deleted       : %d of %d (%.1f%%)\n", deleted_rec, deleted_total, d_pct >> out;
    printf "Recovered from corrupted     : %d of %d (%.1f%%)\n", corrupted_rec, corrupted_total, c_pct >> out;
    print "" >> out;
    printf "Total recovered from simulated: %d of %d (%.1f%%)\n", total_recovered, total_simulated, sim_pct >> out;
    printf "Total recovered from original : %d of %d (%.1f%%)\n", orig_recovered, orig_total, o_pct >> out;

    # Save recovered deleted files
    print "Recovered deleted files:" > deleted_out;
    for (h in deleted_found) {
      printf "%s,%s\n", h, recovered_hashes[h] >> deleted_out;
    }

    # Save recovered corrupted files
    print "Recovered corrupted files:" > corrupted_out;
    for (h in corrupted_found) {
      printf "%s,%s\n", h, recovered_hashes[h] >> corrupted_out;
    }
  }
' "$recovered" "$sim" "$orig"
