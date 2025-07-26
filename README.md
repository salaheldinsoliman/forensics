# Forensic Recovery Tools Evaluation

This project compares multiple file recovery tools by simulating file loss (deletion and corruption) on disk images and evaluating how well each tool recovers those files. The goal is to assess recovery success rates under realistic conditions using reproducible experiments.

---

## Project Structure

```text
~/forensics/
├── data/                      # Clean source data directories (100mb, 1gb, 5gb)
├── images/                   # Raw ext4 disk images to simulate file loss
├── mnt/                      # Mount points for interacting with images
├── manifests/                # Original per-image file manifests
├── manifests_simulated/      # Manifests after deletion/corruption
├── recovery_tools/
│   ├── photorec/             # PhotoRec recovered files and manifest
│   └── sleuthkit/            # Sleuth Kit recovered files and manifest
└── scripts/                  # All automation scripts
```

---

## Setup

### 1. Requirements

* Linux system with `bash`, `coreutils`, `findutils`
* Installed tools:

  * `PhotoRec` (part of `testdisk`)
  * `sleuthkit`
  * `shuf`, `dd`, `sha256sum`, `mount`, `umount`, etc.

```bash
sudo apt update
sudo apt install testdisk sleuthkit coreutils
```

---

## Setup Scripts and What They Do

### `prepare_dirs.sh`

Creates realistic sample datasets in:

```
~/forensics/data/{100mb,1gb,5gb}
```

Each is filled to \~95% of target size using sample files.

---

### `create_images.sh`

* Automatically calculates how much space each data folder needs
* Creates a formatted ext4 disk image for each size
* Copies files into the image

Output: `~/forensics/images/disk_100MB.img`, etc.

---

### `mount_images.sh`

Mounts each image to:

```
~/forensics/mnt/mnt_100MB
~/forensics/mnt/mnt_1GB
...
```

---

### `generate_original_manifest.sh`

Generates a manifest for each image after mounting:

```
~/forensics/manifests/manifest_100mb.csv
```

Includes: file path, hash, and action (default = keep)

---

## Simulation: Deletion and Corruption

### `simulate_deletion_and_corruption.sh`

* Randomly deletes and corrupts a % of files in each mounted image
* Updates the manifest to reflect changes (`deleted`, `corrupted`)
* Re-hashes all files after modification
* Prints used space before and after

Modified manifests are written to:

```
~/forensics/manifests_simulated/
```

---

## Recovery and Evaluation

### `recover_with_tsk.sh`

* Recovers files from each `.img` using Sleuth Kit (`tsk_recover`)
* Stores them under:

  ```
  ~/forensics/recovery_tools/sleuthkit/100mb/
  ```
* Generates a new manifest for each recovered image

---

### PhotoRec recovery

If using PhotoRec, follow its CLI to recover into:

```
~/forensics/recovery_tools/photorec/100mb/
```

Then generate a manifest using the same format.

---

### `verify_recovery_result.sh`

Compares:

1. Original manifest
2. Simulated manifest (with deletion/corruption info)
3. Recovery tool's manifest

Outputs:

* Number and percent of files recovered from each category
* Result saved to:

  ```
  ~/forensics/recovery_tools/<tool>/results.txt
  ```

---

## Running the Full Experiment

```bash
# Step 1: Prepare clean data and disk images
./scripts/prepare_dirs.sh
./scripts/create_images.sh

# Step 2: Mount and baseline
./scripts/mount_images.sh
./scripts/generate_original_manifest.sh

# Step 3: Simulate file loss
./scripts/simulate_deletion_and_corruption.sh

# Step 4: Recover using Sleuth Kit
cd ~/forensics/recovery_tools/sleuthkit
./recover_with_tsk.sh

# Step 5: Evaluate
./scripts/verify_recovery_result.sh \
  ~/forensics/manifests/manifest_100mb.csv \
  ~/forensics/manifests_simulated/manifest_100mb.csv \
  ~/forensics/recovery_tools/sleuthkit/manifest_100mb.csv
```

Repeat for 1GB and 5GB images.

---

## Result Interpretation

The verification script reports:

* Recovery from **kept** files: how well the tool found unmodified data
* Recovery from **deleted** files: true forensic recovery
* Recovery from **corrupted** files: robustness to partial damage
* Total recovered from simulated vs original state


---

## License

MIT License. For research and evaluation use.
