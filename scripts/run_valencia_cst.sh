#!/usr/bin/env bash
# run_valencia_cst.sh — assign VALENCIA community state types to the cohort, from the
# MaLiAmPi species table, and write only aggregates to results/valencia_cst/.
#
# Chain (see docs/CST_VALENCIA.md):
#   classify/tables/tallies_wide.species.csv
#     -> analysis/as_run/convert_maliampi_to_valencia_2026-05-25.py   (unmodified)
#     -> VALENCIA at commit 8559d45 (env/VERSIONS.md, section "VALENCIA")
#     -> scripts/summarise_valencia_cst.py                            (counts and hashes)
#
# The converter resolves every path with expanduser("~") and writes its output to
# ~/valencia_input_maliampi.csv. Rather than edit it, HOME is pointed at a new
# temporary directory holding symlinks to the MaLiAmPi output and the VALENCIA clone,
# so the as-run file runs as it is and writes nothing outside that directory.
# The VALENCIA input and output hold per-specimen abundances: they stay in the
# temporary directory and only their hashes reach the log.
#
# Usage (inside WSL, from the repository root):
#   VALENCIA_DIR=<clone at 8559d45> VALENCIA_PY=<venv>/bin/python \
#   MALIAMPI_OUT=<MaLiAmPi --output dir> [REFERENCE_OUTPUT=<earlier VALENCIA output>] \
#     bash scripts/run_valencia_cst.sh | tee results/valencia_cst/run_valencia_cst.log
set -euo pipefail
: "${VALENCIA_DIR:?clone of github.com/ravel-lab/VALENCIA}"
: "${VALENCIA_PY:?python of a venv built from env/valencia-requirements.txt}"
: "${MALIAMPI_OUT:?MaLiAmPi --output directory}"
COMMIT=8559d454387479f7155333693d854961463c3b15
CONVERTER=analysis/as_run/convert_maliampi_to_valencia_2026-05-25.py
CONVERTER_SHA=9c39f7a163476070767314a4f135181121a912ed7303953d87749a66622a609a
SPECIES_REL=classify/tables/tallies_wide.species.csv
OUT_DIR=results/valencia_cst
die() { echo "STOP: $*" >&2; exit 1; }
VALENCIA_DIR="$(realpath -e "$VALENCIA_DIR")"; MALIAMPI_OUT="$(realpath -e "$MALIAMPI_OUT")"
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
echo "converter == as-run file (sha256 ${CONVERTER_SHA:0:8})"
want=$(grep "^$SPECIES_REL," metadata/maliampi_outputs_manifest.csv | cut -d, -f3)
sha=$(sha256sum < "$MALIAMPI_OUT/$SPECIES_REL" | cut -d' ' -f1)
[ -n "$want" ] && [ "$sha" = "$want" ] || die "species table sha256 is $sha, manifest says $want"
echo "species table == manifest (sha256 ${want:0:8})"
"$VALENCIA_PY" --version

T=$(mktemp -d /tmp/valencia_cst.XXXXXX)
mkdir -p "$T/home/archivos_extra"
ln -s "$MALIAMPI_OUT" "$T/home/archivos_extra/salida_analisis"
ln -s "$VALENCIA_DIR" "$T/home/VALENCIA"

echo "== converter (its own report lists specimens, so it stays in the temporary directory)"
HOME="$T/home" "$VALENCIA_PY" "$CONVERTER" > "$T/convert.log" 2>&1
head -1 "$T/convert.log"

echo "== VALENCIA"
"$VALENCIA_PY" "$VALENCIA_DIR/Valencia.py" -ref "$VALENCIA_DIR/CST_centroids_012920.csv" \
  -i "$T/home/valencia_input_maliampi.csv" -o "$T/valencia_output_maliampi" > "$T/valencia.log" 2>&1
echo "done; pandas FutureWarnings: $(grep -c FutureWarning "$T/valencia.log" || true)"

echo "== summary"
"$VALENCIA_PY" scripts/summarise_valencia_cst.py \
  --species "$MALIAMPI_OUT/$SPECIES_REL" \
  --input "$T/home/valencia_input_maliampi.csv" \
  --output "$T/valencia_output_maliampi.csv" \
  --centroids "$VALENCIA_DIR/CST_centroids_012920.csv" \
  ${REFERENCE_OUTPUT:+--compare "$REFERENCE_OUTPUT"} \
  --out-dir "$OUT_DIR"
date -Is
