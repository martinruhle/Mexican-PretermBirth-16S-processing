#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Launch MaLiAmPi on the Mexican preterm birth cohort.
#
# This is the command that produced the results documented in
# docs/RUN_MALIAMPI.md, with the machine-specific paths lifted into variables.
# The verbatim original, exactly as it appears in the Nextflow log of the final
# session, is in logs/maliampi_launch_command_final_2026-02-18.txt — that file
# is the evidence, this one is the runnable version.
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
# The run did not pull a project by name. It ran a LOCAL CLONE with a modified
# main.nf, which Nextflow logs as `.../assets/jgolob/maliampi_pplacer`. That
# directory name is local: the clone is github.com/jgolob/maliampi at tag
# v3.5.0, with workflow/patches/main.nf.pplacer.patch applied (EPA-NG placement
# swapped for pplacer). Recovered from the WSL machine on 2026-09-24.
#
# Do NOT pass `-r 3239c625a8`. That string is in the log, but it is the script
# id Nextflow computes for the launched main.nf, not a git revision: no such
# commit exists. See env/VERSIONS.md.
#
# Prepare the pipeline directory once:
#   git clone https://github.com/jgolob/maliampi.git "$PIPELINE_DIR"
#   git -C "$PIPELINE_DIR" checkout v3.5.0
#   git -C "$PIPELINE_DIR" apply workflow/patches/main.nf.pplacer.patch
PIPELINE_DIR="${PIPELINE_DIR:-$HOME/.nextflow/assets/jgolob/maliampi_pplacer}"
PIPELINE_COMMIT="333d83ba988157fcae07200dcdc861f6b3306938"   # tag v3.5.0

for p in "$MANIFEST" "$ARF/taxdmp.zip" \
         "$ARF/dedup/1200bp/named/filtered/seqs.fasta" \
         "$ARF/dedup/1200bp/named/filtered/seq_info.csv" \
         "$PIPELINE_DIR/main.nf"; do
  [ -e "$p" ] || { echo "missing input: $p" >&2; exit 1; }
done
mkdir -p "$OUTPUT_DIR" "$WORK_DIR"

# The pipeline directory must be at the pinned commit, with the patch applied.
if command -v git >/dev/null && git -C "$PIPELINE_DIR" rev-parse HEAD >/dev/null 2>&1; then
  have="$(git -C "$PIPELINE_DIR" rev-parse HEAD)"
  [ "$have" = "$PIPELINE_COMMIT" ] || echo "warning: $PIPELINE_DIR is at $have, expected $PIPELINE_COMMIT" >&2
  if git -C "$PIPELINE_DIR" diff --quiet -- main.nf; then
    echo "warning: main.nf is unmodified; apply workflow/patches/main.nf.pplacer.patch" >&2
  fi
fi

args=(
  run "$PIPELINE_DIR"
  -profile standard
  -resume
  -c "$(dirname "${BASH_SOURCE[0]}")/../env/nextflow.config"
  -w "$WORK_DIR"
  --manifest "$MANIFEST"
  --output "$OUTPUT_DIR"
  --repo_fasta "$ARF/dedup/1200bp/named/filtered/seqs.fasta"
  --repo_si "$ARF/dedup/1200bp/named/filtered/seq_info.csv"
  --taxdmp "$ARF/taxdmp.zip"
  # cmalign runs out of memory without this; AlignSV's 1-CPU cap is a process
  # label in env/nextflow.config, not a flag. docs/TROUBLESHOOTING.md §4.
  --cmalign_mxsize 4096
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
