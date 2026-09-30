#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# 🚧 NOT WRITTEN YET — this script refuses to run on purpose.
#
# Intent: re-place the existing sequence variants against the DREAM Challenge
# reference package, so that our phylotypes and the DREAM phylotypes live in the
# same space. Rationale and preconditions: docs/NEXT_STAGE_DREAM_REFPKG.md.
#
# Three things must be settled before this file can be filled in, and none of
# them is settled today:
#
#   1. The DREAM reference package has to be obtained, and its origin, date,
#      version and SHA-256 recorded in docs/NEXT_STAGE_DREAM_REFPKG.md.
#
#   2. The parameter name for supplying a PRE-BUILT reference package has to be
#      read off the workflow source at the pinned commit, 333d83ba9881, with
#      workflow/patches/main.nf.pplacer.patch applied. Our own run never used
#      it — it passed --repo_fasta / --repo_si / --taxdmp and let the pipeline
#      build one — so the name is not in any log we hold. Check with:
#         grep -rn "refpkg" ~/.nextflow/assets/jgolob/maliampi_pplacer/*.nf
#      Writing a guess here would be worse than leaving it blank.
#
#   3. The way to reuse the existing sequence variants instead of re-running
#      DADA2 has to be confirmed. Re-denoising would waste most of the compute
#      and, worse, could produce a different SV set, which would silently break
#      the comparison with the run already documented.
#
# Once those are known, this script should mirror workflow/run_maliampi.sh: same
# pinned commit and patch, same config, a separate --output directory, and the
# same two recording commands at the end (make_output_manifest.sh +
# describe_refpkg.R).
# ---------------------------------------------------------------------------
set -euo pipefail

cat >&2 <<'MSG'
This stage has not been implemented.

Read docs/NEXT_STAGE_DREAM_REFPKG.md, complete preconditions 1-3 listed there,
then write this script. Do not improvise the command line: the parameter names
have to be read off the workflow source, not guessed.
MSG
exit 1
