#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Launch MaLiAmPi on the Mexican preterm birth cohort.
#
# This is the command that produced the results documented in
# docs/RUN_MALIAMPI.md, with the machine-specific paths lifted into variables.
# The verbatim original, exactly as it appears in the Nextflow log, is in
# logs/maliampi_launch_command.txt — that file is the evidence, this one is the
# runnable version.
#
# Requirements: Nextflow 25.04.8, Docker, and about 12 GB of RAM. On the
# original hardware (6 CPUs) a cold run accumulated ~970 CPU hours, spread over
# months of wall clock. Keep -resume and keep the same work directory.
#
# Usage:
#   edit the five paths below, then:  bash workflow/run_maliampi.sh
# ---------------------------------------------------------------------------
set -euo pipefail

# --- paths to edit ---------------------------------------------------------
MANIFEST="${MANIFEST:-$HOME/datos_microbiota_vaginal/Manifiesto.csv}"
OUTPUT_DIR="${OUTPUT_DIR:-$HOME/datos_microbiota_vaginal/salida_analisis}"
WORK_DIR="${WORK_DIR:-$HOME/datos_microbiota_vaginal/working_dir}"
ARF="${ARF:-$HOME/arf_20200420}"          # reference sequence repository
NOTIFY_EMAIL="${NOTIFY_EMAIL:-}"          # optional; leave empty to skip

# --- pinned pipeline -------------------------------------------------------
# NOTE: the original invocation did NOT pass -r; it ran whatever revision the local
# Nextflow asset happened to be at, which the log records as 3239c625a8. Passing it
# explicitly here is a deliberate improvement over what was actually run.
# The revision is what makes this reproducible: it fixes the workflow code and,
# with it, every container tag the pipeline pulls. Do not drop it.
WORKFLOW="jgolob/maliampi_pplacer"
REVISION="3239c625a8"

for p in "$MANIFEST" "$ARF/taxdmp.zip" \
         "$ARF/dedup/1200bp/named/filtered/seqs.fasta" \
         "$ARF/dedup/1200bp/named/filtered/seq_info.csv"; do
  [ -e "$p" ] || { echo "missing input: $p" >&2; exit 1; }
done
mkdir -p "$OUTPUT_DIR" "$WORK_DIR"

args=(
  run "$WORKFLOW" -r "$REVISION"
  -profile standard
  -resume
  -c "$(dirname "${BASH_SOURCE[0]}")/../env/nextflow.config"
  -w "$WORK_DIR"
  --manifest "$MANIFEST"
  --output "$OUTPUT_DIR"
  --repo_fasta "$ARF/dedup/1200bp/named/filtered/seqs.fasta"
  --repo_si "$ARF/dedup/1200bp/named/filtered/seq_info.csv"
  --taxdmp "$ARF/taxdmp.zip"
)
[ -n "$NOTIFY_EMAIL" ] && args+=(--email "$NOTIFY_EMAIL")

# Passing --repo_fasta / --repo_si / --taxdmp is what makes the pipeline BUILD a
# reference package rather than consume one. That choice, and its consequences,
# are documented in docs/REFPKG_PROVENANCE.md.
echo "nextflow ${args[*]}"
nextflow "${args[@]}"

echo
echo "Done. Record the run before you forget it:"
echo "  MALIAMPI_OUT=$OUTPUT_DIR bash scripts/make_output_manifest.sh"
echo "  Rscript scripts/describe_refpkg.R $OUTPUT_DIR/refpkg/refpkg.tar.gz"
