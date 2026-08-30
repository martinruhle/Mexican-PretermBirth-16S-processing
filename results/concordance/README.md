# QIIME2 ↔ MaLiAmPi concordance — results

Read [`docs/CONCORDANCE_QIIME2_MALIAMPI.md`](../../docs/CONCORDANCE_QIIME2_MALIAMPI.md)
first; it states the question, the design and the verdict. This directory holds the
numbers behind it.

## `as_run_2026-05-22/`

The outputs exactly as produced on 2026-05-22 by
[`analysis/as_run/gate_qiime2_maliampi_v2.R`](../../analysis/as_run/gate_qiime2_maliampi_v2.R),
copied here unchanged. They are the **target** that the forthcoming reproducible report
has to reproduce, in the same way a baseline is kept before a refactor.

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

## What will land next to it

`analysis/concordance_qiime2_maliampi.Rmd` and its rendered HTML, with relative paths,
a fixed seed and `sessionInfo()`, plus the aggregated table it produces. Until that
exists, this analysis is documented and archived but **not reproducible from this
repository** — the distinction is deliberate and is stated wherever the results are
quoted.
