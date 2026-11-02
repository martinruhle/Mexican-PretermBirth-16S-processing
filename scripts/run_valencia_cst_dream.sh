#!/usr/bin/env bash
# run_valencia_cst_dream.sh — assign VALENCIA community state types to the DREAM Challenge
# validation specimens with the chain used for the cohort, and write only aggregates to
# results/valencia_cst_dream/.
#
# Chain (see docs/CST_VALENCIA.md, section "DREAM Validation"):
#   Validation.zip (ImmPort SDY2187, DR61; MD5 checked below)
#     -> scripts/build_dream_species_table.py                         (tallies_wide.species.csv)
#     -> analysis/as_run/convert_maliampi_to_valencia_2026-05-25.py   (unmodified)
#     -> VALENCIA at commit 8559d45 (env/VERSIONS.md, section "VALENCIA")
#     -> scripts/summarise_valencia_cst.py       (whole set, unmodified; counts and hashes)
#     -> scripts/summarise_valencia_cst_dream.py (by project; agreement with the Challenge's CST)
#
# scripts/run_valencia_cst.sh stops on any species table other than the cohort's, so this
# is a separate script. As there, HOME is pointed at a new temporary directory so the
# as-run converter runs as it is: the species table built from the archive sits where the
# converter looks for MaLiAmPi's, and the VALENCIA clone is linked in.
# The species table, the VALENCIA input and the VALENCIA output hold per-specimen data.
# They are copied to KEEP_DIR, outside the repository, and only their hashes reach the log.
#
# Usage (inside WSL, from the repository root):
#   VALENCIA_DIR=<clone at 8559d45> VALENCIA_PY=<venv>/bin/python \
#   VALIDATION_ZIP=<Validation.zip, current version> KEEP_DIR=<local directory> \
#     bash scripts/run_valencia_cst_dream.sh | tee results/valencia_cst_dream/run_valencia_cst_dream.log
set -euo pipefail
: "${VALENCIA_DIR:?clone of github.com/ravel-lab/VALENCIA}"
: "${VALENCIA_PY:?python of a venv built from env/valencia-requirements.txt}"
: "${VALIDATION_ZIP:?Validation.zip of ImmPort SDY2187, release DR61}"
: "${KEEP_DIR:?local directory, outside the repository, for the per-specimen files}"
COMMIT=8559d454387479f7155333693d854961463c3b15
CONVERTER=analysis/as_run/convert_maliampi_to_valencia_2026-05-25.py
CONVERTER_SHA=9c39f7a163476070767314a4f135181121a912ed7303953d87749a66622a609a
ZIP_MD5=ce12eec5a51d4cf7db67dfebc9850b88   # Validation.zip in the DR61 manifest (docs/DATA_ACCESS.md)
SPECIES_REL=classify/tables/tallies_wide.species.csv
OUT_DIR=results/valencia_cst_dream
die() { echo "STOP: $*" >&2; exit 1; }
VALENCIA_DIR="$(realpath -e "$VALENCIA_DIR")"; VALIDATION_ZIP="$(realpath -e "$VALIDATION_ZIP")"
mkdir -p "$KEEP_DIR"; KEEP_DIR="$(realpath -e "$KEEP_DIR")"
case "$KEEP_DIR/" in "$(pwd -P)/"*) die "KEEP_DIR is inside the repository";; esac
date -Is

echo "== checks"
head=$(git -C "$VALENCIA_DIR" rev-parse HEAD)
[ "$head" = "$COMMIT" ] || die "VALENCIA clone is at $head, not $COMMIT"
echo "VALENCIA clone at $COMMIT"
changes=$(git -C "$VALENCIA_DIR" status --short)
[ -z "$changes" ] || die "VALENCIA clone has local changes"
echo "VALENCIA clone has no local changes"
sha=$(sha256sum < "$CONVERTER" | cut -d' ' -f1)
[ "$sha" = "$CONVERTER_SHA" ] || die "converter sha256 is $sha, not the as-run file's"
echo "converter == as-run file (sha256 $CONVERTER_SHA)"
md5=$(md5sum < "$VALIDATION_ZIP" | cut -d' ' -f1)
[ "$md5" = "$ZIP_MD5" ] || die "Validation.zip MD5 is $md5, not the DR61 manifest's $ZIP_MD5"
echo "Validation.zip == DR61 manifest (MD5 $ZIP_MD5, $(stat -c %s "$VALIDATION_ZIP") bytes)"
"$VALENCIA_PY" --version

T=$(mktemp -d /tmp/valencia_cst_dream.XXXXXX)
"$VALENCIA_PY" -m zipfile -e "$VALIDATION_ZIP" "$T/zip"
V="$T/zip/Validation"
mkdir -p "$T/home/archivos_extra/salida_analisis/$(dirname "$SPECIES_REL")"
ln -s "$VALENCIA_DIR" "$T/home/VALENCIA"

echo "== species table from sp_sv_long.csv and sv_taxonomy.csv"
"$VALENCIA_PY" scripts/build_dream_species_table.py --validation-dir "$V" \
  --out "$T/home/archivos_extra/salida_analisis/$SPECIES_REL" \
  --projects "$T/specimen_project.csv"

echo "== converter (its own report lists specimens, so it stays in the temporary directory)"
HOME="$T/home" "$VALENCIA_PY" "$CONVERTER" > "$T/convert.log" 2>&1
head -1 "$T/convert.log"

echo "== VALENCIA"
"$VALENCIA_PY" "$VALENCIA_DIR/Valencia.py" -ref "$VALENCIA_DIR/CST_centroids_012920.csv" \
  -i "$T/home/valencia_input_maliampi.csv" -o "$T/valencia_output_dream" > "$T/valencia.log" 2>&1
echo "done; pandas FutureWarnings: $(grep -c FutureWarning "$T/valencia.log" || true)"

echo "== kept outside the repository, in KEEP_DIR"
cp "$T/home/archivos_extra/salida_analisis/$SPECIES_REL" "$KEEP_DIR/tallies_wide.species.dream_validation.csv"
cp "$T/home/valencia_input_maliampi.csv" "$KEEP_DIR/valencia_input_dream_validation.csv"
cp "$T/valencia_output_dream.csv" "$KEEP_DIR/valencia_output_dream_validation.csv"
cp "$T/specimen_project.csv" "$KEEP_DIR/specimen_project_dream_validation.csv"
(cd "$KEEP_DIR" && sha256sum tallies_wide.species.dream_validation.csv \
  valencia_input_dream_validation.csv valencia_output_dream_validation.csv \
  specimen_project_dream_validation.csv)

echo "== summary, whole set (compared with the Challenge's cst_valencia.csv, specimen -> sampleID)"
"$VALENCIA_PY" -c 'import sys, pandas as pd
pd.read_csv(sys.argv[1]).rename(columns={"specimen": "sampleID"}).to_csv(sys.argv[2], index=False)' \
  "$V/community_state_types/cst_valencia.csv" "$T/cst_valencia_dream.csv"
echo "Challenge's cst_valencia.csv sha256 $(sha256sum < "$V/community_state_types/cst_valencia.csv" | cut -d' ' -f1)"
"$VALENCIA_PY" scripts/summarise_valencia_cst.py \
  --species "$T/home/archivos_extra/salida_analisis/$SPECIES_REL" \
  --input "$T/home/valencia_input_maliampi.csv" \
  --output "$T/valencia_output_dream.csv" \
  --centroids "$VALENCIA_DIR/CST_centroids_012920.csv" \
  --compare "$T/cst_valencia_dream.csv" \
  --out-dir "$OUT_DIR"

echo "== summary by project"
"$VALENCIA_PY" scripts/summarise_valencia_cst_dream.py \
  --species "$T/home/archivos_extra/salida_analisis/$SPECIES_REL" \
  --projects "$T/specimen_project.csv" \
  --input "$T/home/valencia_input_maliampi.csv" \
  --output "$T/valencia_output_dream.csv" \
  --dream-cst "$V/community_state_types/cst_valencia.csv" \
  --out-dir "$OUT_DIR"
rm -rf "$T"
date -Is
