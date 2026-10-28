#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Rebuild metadata/maliampi_outputs_manifest.csv
#
# The MaLiAmPi outputs themselves are NOT versioned here (they are large and
# participant-level; see docs/DATA_ACCESS.md). What is versioned is this
# manifest: for every output file, its size and its SHA-256. That is what lets
# somebody else confirm they are holding the same tables this project used.
#
# Usage:
#   MALIAMPI_OUT=/path/to/salida_analisis bash scripts/make_output_manifest.sh
#
# MALIAMPI_OUT must point at the --output directory of the MaLiAmPi run, i.e.
# the directory that contains sv/, refpkg/, placement/ and classify/.
#
# After the MaLiAmPi outputs, the manifest also lists LINKED_FILES: files that
# are not MaLiAmPi outputs but that every join between these tables and the
# cohort depends on. Their paths are relative to the repository root, and they
# are git-ignored (clinical metadata); only their hash is versioned. If one is
# absent locally, its recorded row is carried over unchanged, with a warning:
# it is then listed but NOT verified.
#
# Last come VALENCIA_FILES: the VALENCIA input and output computed from
# classify/tables/tallies_wide.species.csv (docs/CST_VALENCIA.md). They hold
# per-specimen abundances and are not versioned; they are listed as
# valencia/<name> and hashed from VALENCIA_DIR, the directory that holds them.
# If VALENCIA_DIR is unset or a file is missing, the recorded row is carried
# over with the same warning as above.
# ---------------------------------------------------------------------------
set -euo pipefail

OUT_DIR="${MALIAMPI_OUT:?set MALIAMPI_OUT to the MaLiAmPi --output directory}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$REPO_ROOT/metadata/maliampi_outputs_manifest.csv"

# Canonical specimen (Au###) <-> participant map; see docs/CONCORDANCE_QIIME2_MALIAMPI.md §6.
LINKED_FILES=(metadata/mapa_muestras_2026-09-20.csv)

# VALENCIA input and output of 2026-05-25; see docs/CST_VALENCIA.md.
VALENCIA_FILES=(valencia_input_maliampi.csv valencia_output_maliampi.csv)
VALENCIA_DIR="${VALENCIA_DIR:-}"

[ -d "$OUT_DIR" ] || { echo "not a directory: $OUT_DIR" >&2; exit 1; }

PREV_LINKED="$(grep -E '^(metadata|valencia)/' "$DEST" 2>/dev/null || true)"

echo "relative_path,bytes,sha256" > "$DEST"

# errM/ holds one small per-batch DADA2 error model; it is excluded to keep the
# manifest readable. Everything else under the four output directories is listed.
find "$OUT_DIR" -type f -not -path "*/errM/*" -not -path "*/fastqc/*" \
  | LC_ALL=C sort \
  | while IFS= read -r f; do
      rel="${f#"$OUT_DIR"/}"
      size=$(stat -c %s "$f")
      hash=$(sha256sum "$f" | cut -d' ' -f1)
      printf '%s,%s,%s\n' "$rel" "$size" "$hash" >> "$DEST"
    done

for rel in "${LINKED_FILES[@]}"; do
  f="$REPO_ROOT/$rel"
  if [ -f "$f" ]; then
    printf '%s,%s,%s\n' "$rel" "$(stat -c %s "$f")" "$(sha256sum "$f" | cut -d' ' -f1)" >> "$DEST"
  else
    row="$(printf '%s\n' "$PREV_LINKED" | grep "^$rel," || true)"
    [ -n "$row" ] || { echo "no local copy and no recorded row for $rel" >&2; exit 1; }
    printf '%s\n' "$row" >> "$DEST"
    echo "warning: $rel is not present locally; its recorded row was carried over, NOT verified" >&2
  fi
done

for name in "${VALENCIA_FILES[@]}"; do
  rel="valencia/$name"
  f="$VALENCIA_DIR/$name"
  if [ -n "$VALENCIA_DIR" ] && [ -f "$f" ]; then
    printf '%s,%s,%s\n' "$rel" "$(stat -c %s "$f")" "$(sha256sum "$f" | cut -d' ' -f1)" >> "$DEST"
  else
    row="$(printf '%s\n' "$PREV_LINKED" | grep "^$rel," || true)"
    [ -n "$row" ] || { echo "no file under VALENCIA_DIR and no recorded row for $rel" >&2; exit 1; }
    printf '%s\n' "$row" >> "$DEST"
    echo "warning: $rel is not present locally; its recorded row was carried over, NOT verified" >&2
  fi
done

echo "wrote $DEST ($(($(wc -l < "$DEST") - 1)) files)"
