# Do QIIME2 and MaLiAmPi describe the same microbiome?

**Status: analysis run and reported; not yet reproducible from this repository.**
The comparison was carried out on 2026-05-22 and presented at the fourth doctoral
tutorial. Its outputs are archived here verbatim. What is still missing is the part
that makes it *reproducible*: a self-contained report with relative paths, a fixed
seed and a recorded session. See [§5](#5-what-is-still-missing).

---

## 1. Why the question matters

The published manuscript was built on genus-level tables from **QIIME2/DADA2**.
Everything that comes next — species resolution, community state types, phylotypes,
external validation against the DREAM Challenge — requires **MaLiAmPi**. Switching
pipelines is only safe if both describe the same underlying microbiome. If they do
not, every result carried forward from the manuscript has to be re-established rather
than assumed.

So the question is a gate, not a curiosity: *does the change of pipeline change the
data?*

## 2. Design

Both pipelines were reduced to their genus-level count tables over the same 110
specimens, and compared at four levels, each able to fail independently:

| Question | Statistic |
|---|---|
| Does each genus vary the same way across specimens? | Spearman correlation per taxon |
| Do both pipelines call the same genera dominant in a specimen? | Jaccard index of the top-5 and top-10 |
| Are the whole abundance profiles similar, specimen by specimen? | paired Bray–Curtis dissimilarity |
| Is the global structure of the specimen space the same? | Mantel test and Procrustes on the distance matrices |

Two tracks were computed: **`genus`** (only taxa resolved to genus) and **`all_taxa`**
(including material that could not be assigned at genus level), so that the answer does
not depend on how unassigned mass is treated. Genus names were harmonized before
matching; that curation is switchable in the script and both variants were reported.

## 3. Result, as run on 2026-05-22

Values below are taken verbatim from
[`results/concordance/as_run_2026-05-22/report_curation_on.md`](../results/concordance/as_run_2026-05-22/report_curation_on.md)
(genus track, name curation enabled).

| | Value |
|---|---|
| Genera reported: MaLiAmPi / QIIME2 / **shared** | 314 / 77 / **65** (63 matched directly, 2 through curation; 249 MaLiAmPi-only, 12 QIIME2-only) |
| Specimens compared | 110 |
| Share of each specimen's mass carried by the 65 shared genera | MaLiAmPi median **0.999** (IQR 0.997–1.000); QIIME2 median **0.996** (IQR 0.993–0.999) |
| Spearman per taxon | median **0.529** (IQR 0.396–0.701), n = 50 evaluable; 13 genera above 0.7, 9 below 0.3 |
| Jaccard, top-5 genera per specimen | median **0.667** |
| Jaccard, top-10 genera per specimen | median **0.538** |
| Paired Bray–Curtis | median **0.099** (IQR 0.059–0.156) |
| Mantel (Spearman) between distance matrices | **r = 0.940**, p = 0.001 |
| Procrustes | M² = 0.159, **correlation = 0.917**, p = 0.001 |

The `all_taxa` track gives the same picture (coverage 0.974 / 0.992; Spearman median
0.527; identical per-specimen and global statistics), so the conclusion does not hinge
on unassigned mass.

### Reading

- The 65 shared genera are not a fragment of the data — they carry **more than 99 % of
  the sequenced mass** in both pipelines. The comparison is about the bulk of the
  microbiome, not its tail.
- **Individual genera agree moderately** (median ρ ≈ 0.53). This is expected: the two
  pipelines use different classification algorithms and different reference databases.
  It is also a warning with teeth — *Mycoplasma*, the one genus that reached FDR
  significance in the published analysis, is among the poorly correlated ones. Any
  claim about a single taxon must be re-checked in both pipelines before it is carried
  forward.
- **Specimens agree well** (Bray–Curtis median 0.099; the top-5 genera coincide in most
  specimens).
- **The global structure agrees very well** (Mantel 0.94, Procrustes 0.92). The two
  pipelines arrange the 110 specimens in nearly the same configuration.

### Verdict

For analyses that learn from the global structure of the specimen space — which is what
the modelling framework does — **MaLiAmPi is a valid substitute for QIIME2/DADA2**, and
the next stage of the project can proceed on it. For claims about individual taxa,
agreement must be verified taxon by taxon.

> **Discrepancy on record.** The tutorial slide reports a per-taxon median of 0.51,
> while the archived report says 0.529 and the spoken commentary said 0.53. The 0.529
> in the report is the value this repository stands behind; the slide value is not
> reproducible from the archived outputs. To be resolved when the analysis is ported
> (§5) — flagged rather than quietly harmonized.

## 4. What was actually run

| | |
|---|---|
| Script | [`analysis/as_run/gate_qiime2_maliampi_v2.R`](../analysis/as_run/gate_qiime2_maliampi_v2.R) — kept verbatim, absolute paths and all, because it is the evidence of what produced the numbers above |
| MaLiAmPi input | `classify/tables/tallies_wide.genus.csv` from the run documented in [`RUN_MALIAMPI.md`](RUN_MALIAMPI.md) |
| QIIME2 input | `genus_rel_filtered_conc_2026-03-06_abs.csv` — **note: not the same file as the matrix behind the published manuscript** (`genus_rel_filtered_2025-05-25_abs.csv`). Which processing steps separate the two is not documented anywhere yet; see §5 |
| Date | 2026-05-22 |
| Outputs | [`results/concordance/as_run_2026-05-22/`](../results/concordance/as_run_2026-05-22/) — two reports, per-track tables, four figures per track |
| Earlier version | [`analysis/as_run/gate_qiime2_maliampi_v1.R`](../analysis/as_run/gate_qiime2_maliampi_v1.R), superseded; kept for history |

## 5. What is still missing

The analysis exists; the *reproducible* analysis does not. To close it:

1. **Port the script to a self-contained report** (`analysis/concordance_qiime2_maliampi.Rmd`)
   with no absolute paths and no `setwd()`, inputs resolved relative to the project
   root, a fixed seed, and `sessionInfo()` printed at the end.
2. **Render it** to `analysis/concordance_qiime2_maliampi.html` and commit both.
3. **Reproduce the archived numbers.** The report in
   `results/concordance/as_run_2026-05-22/` is the target: the ported version must
   return the same 65 shared genera, the same median ρ = 0.529, the same Mantel 0.940
   and Procrustes 0.917. A difference is an investigation, not noise.
4. **Write down the QIIME2 input chain** — which file, produced by which steps, from
   which QIIME2 artifacts — so that the `_conc_2026-03-06` versus `2025-05-25`
   difference stops being an unexplained detail.
5. **Settle the name curation.** The script carries a flag
   (`CURACION_EXTENDIDA`) that merges *Mycoplasma* with *Mesomycoplasma*, *Prevotella*
   with *Hoylesella* and *Segatella*, and *Atopobium* into *Fannyhessea*, and strips
   NCBI suffixes such as `<high GC Gram+>`. Both settings were reported; the ported
   version must state which one it uses and why.

No abundance table for any participant belongs in this repository at any point in the
above; see [`DATA_ACCESS.md`](DATA_ACCESS.md).

---

| | |
|---|---|
| Written | 2026-08-30 |
| Analysis run | 2026-05-22 |
| Reviewed by | *pending* |
