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
# ---------------------------------------------------------------------------
set -euo pipefail

OUT_DIR="${MALIAMPI_OUT:?set MALIAMPI_OUT to the MaLiAmPi --output directory}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$REPO_ROOT/metadata/maliampi_outputs_manifest.csv"

[ -d "$OUT_DIR" ] || { echo "not a directory: $OUT_DIR" >&2; exit 1; }

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

echo "wrote $DEST ($(($(wc -l < "$DEST") - 1)) files)"
