# Known issues

Open questions about this processing run, listed rather than smoothed over. Each one is
something a reader could otherwise trip on, or something that would have to be resolved
before the affected result is relied on.

Items are closed by editing this file and the document that carries the claim.

---

## 1. The exact command of the successful run has not been recovered

**Status:** open. **Blocks:** exact reproduction of the run.

The only Nextflow log kept in the project is from the `Nov-06` session
(`jovial_mercator`), which **failed** at `make_refpkg_wf:TaxtableForSI`. The final
successful run additionally passed `--cmalign_mxsize 4096` and a reduced CPU count for
`AlignSV`, but that command line is not in any file we hold.

To close it, on the WSL machine:

```bash
cd ~/datos_microbiota_vaginal
cat .nextflow/history      # one line per run, with the full command
ls -lt .nextflow.log*
```

Then replace the command in [`docs/RUN_MALIAMPI.md`](docs/RUN_MALIAMPI.md) and in
[`workflow/run_maliampi.sh`](workflow/run_maliampi.sh), and drop the warning boxes.

## 2. The `main.nf` patch is described in prose, not committed

**Status:** open. **Blocks:** running the pipeline from a clean checkout.

The run used a locally modified `main.nf` (EPA-NG placement swapped for pplacer). The
change is written out in [`docs/RUN_MALIAMPI.md` §4](docs/RUN_MALIAMPI.md), but the patch
file itself lives only on the WSL machine. Generate it with `git diff main.nf` in
`~/.nextflow/assets/jgolob/maliampi_pplacer` and commit it under `workflow/patches/`.

## 3. `--cmalign_mxsize 4096` and the `AlignSV` CPU count are unverified

**Status:** open. **Blocks:** nothing today; matters when the run is repeated.

Both values come from the project's working history, not from a log. Confirm against
`.nextflow/history` (see item 1). Recorded in
[`docs/TROUBLESHOOTING.md` §4](docs/TROUBLESHOOTING.md) with the same caveat.

## 4. `Au122_S43` versus `Au122_S41`

**Status:** open. **Blocks:** any join on sample ID for that one specimen.

The manifest and the DADA2 outputs use `Au122_S43`. `tallies_wide.species.csv` reports
`Au122_S41`. One of the two is wrong, and until it is resolved against the laboratory
records, any join between the MaLiAmPi tables and the clinical metadata is potentially
misaligned **for that specimen**. Nothing else is affected.

## 5. Where the `classify/` tables actually live

**Status:** open. **Blocks:** nothing; it is a provenance ambiguity.

The run's `--output` was `~/datos_microbiota_vaginal/salida_analisis/`, but the tables
used downstream were taken from a copy under `archivos_extra/salida_analisis/`. Whether
that is a manual copy, or the output of a second run, has not been established. The
checksums in
[`metadata/maliampi_outputs_manifest.csv`](metadata/maliampi_outputs_manifest.csv) were
computed on the `archivos_extra` copy — which is the copy every number in this repository
describes. To close:

```bash
md5sum ~/datos_microbiota_vaginal/salida_analisis/classify/tables/tallies_wide.species.csv
md5sum ~/archivos_extra/salida_analisis/classify/tables/tallies_wide.species.csv
```

## 6. 111 specimens here, 110 in the analysis matrix

**Status:** open. **Blocks:** nothing; it is an unexplained difference.

The MaLiAmPi tables carry 111 specimen columns; the genus matrix used in
[`Mexican-PretermBirth-analysis`](https://github.com/martinruhle/Mexican-PretermBirth-analysis)
has 110 rows. `failed_specimens.csv` is empty, so nothing failed inside MaLiAmPi — the
specimen is dropped somewhere in the QIIME2 / decontam / filtering chain, which is itself
undocumented (item 7).

## 7. The QIIME2 side of the input chain is undocumented

**Status:** open. **Blocks:** reproducing the concordance analysis from scratch.

The concordance analysis consumed `genus_rel_filtered_conc_2026-03-06_abs.csv`, which is
**not** the matrix behind the published manuscript
(`genus_rel_filtered_2025-05-25_abs.csv`). The steps separating them — decontam,
filtering — live in loose `.Rmd` files outside any repository. See
[`docs/CONCORDANCE_QIIME2_MALIAMPI.md` §5](docs/CONCORDANCE_QIIME2_MALIAMPI.md).

## 8. Sample ID formats have not been checked end to end

**Status:** open.

That the `Au<N>_S<N>` identifiers in the MaLiAmPi tables match exactly those in the
clinical metadata and in the QIIME2 matrices has been assumed, not verified. Item 4 is
one known instance where they do not.

## 9. Container tags are only partially recorded

**Status:** open. **Blocks:** full version pinning.

Only `golob/taxtastic:0.9.5D` appears in the surviving log. The tags for DADA2, pplacer,
barcodecop, TrimGalore and FastQC are pinned by workflow revision `3239c625a8` but have
not been written down. See [`env/VERSIONS.md`](env/VERSIONS.md).

---

## Resolved

**"177,503 ASVs" was a category error.** Earlier project material quoted 177,503 as a
count of sequence variants. It is the number of specimen–variant *pairs* with a non-zero
count in the long-format table. The number of distinct sequence variants is **21,382**.
Both were re-derived from `sv/dada2.specimen.sv.long.csv` on 2026-08-30 (177,503 rows,
21,382 distinct `sv` values, 111 distinct specimens, 28,277,142 total reads) and this
repository uses 21,382 throughout.

Searched for the incorrect figure: `Mexican-PretermBirth-analysis` (no matches) and the
text of the fourth tutorial presentation (no matches — it quotes neither number). The
only hits anywhere were coincidental digit runs inside binary and data files. Nothing
found needs correcting, but the manuscript PDF was not searched.

---

*Last updated 2026-08-30.*
