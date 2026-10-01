# Analysis

Reports that read the processing outputs and answer a question about them. Modelling
does not live here — that is the
[analysis compendium](https://github.com/martinruhle/Mexican-PretermBirth-analysis).

## `as_run/`

Scripts kept **exactly as they were executed**, absolute paths and all. They are
evidence, not products: they document what produced the archived numbers in
`results/`. They are not expected to run on another machine, and they should not be
edited — if a script needs fixing, the fix belongs in a new reproducible report, and
the as-run copy stays untouched.

| File | Ran on | Produced |
|---|---|---|
| `gate_qiime2_maliampi_v3.R` | 2026-09-21 | [`results/concordance/as_run_2026-09-21/`](../results/concordance/as_run_2026-09-21/) — current; reproduced by `concordance_qiime2_maliampi.Rmd` (below) |
| `verify_sample_pairing_2026-09-21.R` | 2026-09-21 | `pairing_verification.log` in the same directory: the specimen-by-specimen check of v2's input — 106 rows hold their own specimen's counts, 4 (Au52, Au197, Au179, Au203) hold their pair partner's |
| `gate_qiime2_maliampi_v2.R` | 2026-05-22 | [`results/concordance/as_run_2026-05-22/`](../results/concordance/as_run_2026-05-22/) — superseded by v3, which re-anchors those 4 of the 110 specimens |
| `gate_qiime2_maliampi_v1.R` | earlier | superseded by v2; kept for history |

v3 is v2 plus one block (4a) and nothing else, so `diff v2 v3` shows the entire change.

## `concordance_qiime2_maliampi.Rmd`

The reproducible port of `as_run/gate_qiime2_maliampi_v3.R`, rendered to
[`concordance_qiime2_maliampi.html`](concordance_qiime2_maliampi.html). It has no absolute
paths and no `setwd()`. It sets the seed before each Mantel test, as v3 does, and ends with
`sessionInfo()`. From the repository root:

```bash
Rscript -e "rmarkdown::render('analysis/concordance_qiime2_maliampi.Rmd')"
```

It needs R with tidyverse, readxl, vegan, patchwork, ggrepel, scales, here, digest and
rmarkdown, and pandoc. RStudio ships one; outside RStudio, set `RSTUDIO_PANDOC` to the
directory that holds it.

**Inputs.** There are three, all participant-level, so none is in the repository. Each
is checked against its recorded SHA-256 before it is read:

| Parameter | Default | File |
|---|---|---|
| `maliampi_out` | `data/maliampi` | `classify/tables/tallies_wide.genus.csv` under it |
| `qiime2_dir` | `data/qiime2` | `level-6_vag138.xlsx` under it |
| `specimen_map` | `metadata/mapa_muestras_2026-09-20.csv` | the canonical specimen map |

The defaults are git-ignored. If the files live elsewhere, pass their location, e.g.
`rmarkdown::render(..., params = list(maliampi_out = "<dir>", qiime2_dir = "<dir>"))`.

**Checks.** The render stops if the genus-track targets (median ρ 0.585, 15 genera above
0.7, Mantel 0.958, Procrustes 0.925, 65 shared genera) differ from the archived run, if
any line of the archived reports differs, or if any archived table differs. On
2026-10-01 everything matched: the nine CSV tables and the eight figures are identical
byte for byte, and the four lists of unmatched taxa hold the same lines (the port writes
them in C-locale order).

**Outputs.** Tables and figures go to
[`results/concordance/reproducible/`](../results/concordance/reproducible/).

It differs from v3 in what it reads, not in what it computes. v3 also read
`genus_rel_filtered_conc_2026-03-06_abs.csv` for taxon names and row labels, and replaced
its counts. The port takes the specimens from the canonical map and derives the names from
the raw QIIME2 export's lineages, which gives the same 97 names in the same order. See
[`docs/CONCORDANCE_QIIME2_MALIAMPI.md` §7](../docs/CONCORDANCE_QIIME2_MALIAMPI.md).
