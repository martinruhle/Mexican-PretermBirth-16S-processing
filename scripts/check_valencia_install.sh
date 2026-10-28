#!/usr/bin/env bash
# check_valencia_install.sh — install VALENCIA from scratch at the pinned commit and
# confirm that it reproduces, byte for byte, the community state types computed on
# 2026-05-25 (see env/VERSIONS.md, section "VALENCIA").
#
# Runs on the WSL machine that ran the analysis. Creates a new temporary directory with
# a fresh clone and a fresh venv; it never touches ~/VALENCIA or ~/valencia_env, and only
# reads the files of 2026-05-25:
#   ~/valencia_input_maliampi.csv    VALENCIA input   (sha256 7388b531...)
#   ~/valencia_output_maliampi.csv   VALENCIA output  (sha256 0805b305...)
#   ~/convert_maliampi_to_valencia.py, the converter that wrote that input
# Those files hold per-specimen abundances and stay out of the repository; only their
# hashes are printed.
#
# Usage (from the repository root, inside WSL):
#   bash scripts/check_valencia_install.sh env/valencia-requirements.txt \
#     | tee results/valencia_install_check/check_valencia_install.log
set -euo pipefail
REQ="$(realpath "$1")"
COMMIT=8559d454387479f7155333693d854961463c3b15
T=$(mktemp -d /tmp/valencia_fresh.XXXXXX)
echo "tmp: $T"; date -Is
cd "$T"

echo "== clone"
git clone --quiet https://github.com/ravel-lab/VALENCIA.git
git -C VALENCIA -c advice.detachedHead=false checkout --quiet "$COMMIT"
git -C VALENCIA rev-parse HEAD
echo "local changes: $(git -C VALENCIA status --short | wc -l)"

echo "== venv"
/usr/bin/python3 -m venv venv
venv/bin/python --version
venv/bin/pip --version
venv/bin/pip install --quiet --disable-pip-version-check -r "$REQ"
venv/bin/pip freeze --disable-pip-version-check > freeze_fresh.txt
diff <(grep -E '^[A-Za-z]' "$REQ" | sort) <(sort freeze_fresh.txt) \
  && echo "pip freeze of the new venv == pins in $(basename "$REQ") ($(wc -l < freeze_fresh.txt) packages)"

echo "== VALENCIA files: new clone vs the clone that ran"
sha256sum VALENCIA/Valencia.py VALENCIA/CST_centroids_012920.csv \
  ~/VALENCIA/Valencia.py ~/VALENCIA/CST_centroids_012920.csv

echo "== A: VALENCIA on the input of 2026-05-25"
venv/bin/python VALENCIA/Valencia.py -ref VALENCIA/CST_centroids_012920.csv \
  -i ~/valencia_input_maliampi.csv -o "$T/out_A" -p "$T/plot_A" > runA.log 2>&1
echo "pandas FutureWarnings: $(grep -c FutureWarning runA.log)"
grep -m1 -o "FutureWarning: Series.__getitem__ treating keys as positions is deprecated" runA.log || true
sha256sum ~/valencia_input_maliampi.csv out_A.csv ~/valencia_output_maliampi.csv
cmp out_A.csv ~/valencia_output_maliampi.csv && echo "A: output byte-identical to 2026-05-25"

echo "== B: converter of 2026-05-25 (unmodified copy) -> VALENCIA"
# The converter resolves every path with expanduser("~"); pointing HOME at the temp dir
# makes it read the new clone's centroids and write its output here.
mkdir home
ln -s ~/archivos_extra home/archivos_extra
ln -s "$T/VALENCIA" home/VALENCIA
cp ~/convert_maliampi_to_valencia.py .
sha256sum convert_maliampi_to_valencia.py
HOME="$T/home" venv/bin/python convert_maliampi_to_valencia.py > runB_convert.log 2>&1
head -1 runB_convert.log
venv/bin/python VALENCIA/Valencia.py -ref VALENCIA/CST_centroids_012920.csv \
  -i home/valencia_input_maliampi.csv -o "$T/out_B" > runB.log 2>&1
sha256sum home/valencia_input_maliampi.csv out_B.csv
cmp home/valencia_input_maliampi.csv ~/valencia_input_maliampi.csv && echo "B: input byte-identical to 2026-05-25"
cmp out_B.csv ~/valencia_output_maliampi.csv && echo "B: output byte-identical to 2026-05-25"

echo "== originals untouched"
git -C ~/VALENCIA rev-parse HEAD
ls -l --time-style=full-iso ~/valencia_env/pyvenv.cfg ~/valencia_input_maliampi.csv ~/valencia_output_maliampi.csv \
  | awk '{print $6, $7, $9}'
date -Is
