# QIIME2 ↔ MaLiAmPi concordance — results

Read [`docs/CONCORDANCE_QIIME2_MALIAMPI.md`](../../docs/CONCORDANCE_QIIME2_MALIAMPI.md)
first; it states the question, the design and the verdict. This directory holds the
numbers behind it.

## `as_run_2026-09-21/` — current

The outputs exactly as produced on 2026-09-21 by
[`analysis/as_run/gate_qiime2_maliampi_v3.R`](../../analysis/as_run/gate_qiime2_maliampi_v3.R),
copied here unchanged. These results use the canonical specimen map, with every
MaLiAmPi ↔ QIIME2 pairing verified. They are the **target** that the reproducible
report, [`analysis/concordance_qiime2_maliampi.Rmd`](../../analysis/concordance_qiime2_maliampi.Rmd),
has to reproduce, in the same way a baseline is kept before a refactor.

Same layout as the May directory below, plus two logs:

| Path | Contents |
|---|---|
| `run_curation_on.log` | console output of the curation-on run, with package versions and the four re-anchored rows (R's "built under" warnings stripped) |
| `pairing_verification.log` | output of [`verify_sample_pairing_2026-09-21.R`](../../analysis/as_run/verify_sample_pairing_2026-09-21.R): input hashes, then the four checks (label, count fingerprint, sequencing depth, sample-sheet position). Counts and specimen IDs only, with no participant, visit or outcome |

## `as_run_2026-05-22/` — superseded, kept as history

The outputs exactly as produced on 2026-05-22 by
[`analysis/as_run/gate_qiime2_maliampi_v2.R`](../../analysis/as_run/gate_qiime2_maliampi_v2.R),
copied here unchanged. **Its pairing is by label, and in 4 of the 110 specimens the QIIME2
row under the label holds the pair partner's counts** (Au52 ↔ Au197, Au179 ↔ Au203);
`as_run_2026-09-21/` re-anchors those four to their own profile. See
[`docs/CONCORDANCE_QIIME2_MALIAMPI.md` §4](../../docs/CONCORDANCE_QIIME2_MALIAMPI.md).
Re-running v2 unchanged on 2026-09-21 reproduced these files byte for byte, so they are a
faithful record of that run.

| Path | Contents |
|---|---|
| `report_curation_on.md` | summary report with genus-name curation enabled — the variant the conclusions are stated from |
| `report_curation_off.md` | the same report with curation disabled, for contrast |
| `tables/genus/`, `tables/all_taxa/` | `spearman_per_taxon.csv` (ρ, p, prevalence and mean abundance per genus), `bray_curtis_per_sample.csv`, `topk_jaccard_per_sample.csv`, `cobertura_interseccion.csv`, and the lists of taxa with no counterpart in the other pipeline |
| `figures/genus/`, `figures/all_taxa/` | correlation versus prevalence, intersection coverage, per-specimen agreement, Procrustes on the PCoA |

Two tracks are reported throughout: `genus` (taxa resolved to genus) and `all_taxa`
(including unassigned material). They agree, which is the point of computing both.

Nothing here is a per-participant abundance table: the tables carry one row per genus
or one derived statistic per specimen. See
[`docs/DATA_ACCESS.md`](../../docs/DATA_ACCESS.md).

## `reproducible/` — written by the reproducible report

The tables and figures that
[`analysis/concordance_qiime2_maliampi.Rmd`](../../analysis/concordance_qiime2_maliampi.Rmd)
writes each time it is rendered. The layout and file names are those of
`as_run_2026-09-21/`, so the two directories can be compared file by file, and the report
makes that comparison itself. As rendered on 2026-10-01, every table and figure is
identical byte for byte to its `as_run_2026-09-21/` counterpart. The one exception is
order: three of the four `*_sin_match.txt` lists hold the same lines in C-locale order.
There are no `report_*.md` files here; the rendered HTML next to the `.Rmd` takes their
place.
