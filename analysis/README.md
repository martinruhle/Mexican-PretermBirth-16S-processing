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
| `gate_qiime2_maliampi_v3.R` | 2026-09-21 | [`results/concordance/as_run_2026-09-21/`](../results/concordance/as_run_2026-09-21/) — current |
| `verify_sample_pairing_2026-09-21.R` | 2026-09-21 | `pairing_verification.log` in the same directory: the specimen-by-specimen check of v2's input — 106 rows hold their own specimen's counts, 4 (Au52, Au197, Au179, Au203) hold their pair partner's |
| `gate_qiime2_maliampi_v2.R` | 2026-05-22 | [`results/concordance/as_run_2026-05-22/`](../results/concordance/as_run_2026-05-22/) — superseded by v3, which re-anchors those 4 of the 110 specimens |
| `gate_qiime2_maliampi_v1.R` | earlier | superseded by v2; kept for history |

v3 is v2 plus one block (4a) and nothing else, so `diff v2 v3` shows the entire change.

## What belongs here next

`concordance_qiime2_maliampi.Rmd` — the reproducible port of the v2 script: no absolute
paths, no `setwd()`, inputs resolved relative to the project root, a fixed seed, and
`sessionInfo()` at the end. It has to return the numbers already archived in
`results/concordance/as_run_2026-09-21/`; a difference is an investigation, not noise.
Requirements are spelled out in
[`docs/CONCORDANCE_QIIME2_MALIAMPI.md` §5](../docs/CONCORDANCE_QIIME2_MALIAMPI.md).
