# Do QIIME2 and MaLiAmPi describe the same microbiome?

**Status: re-run on 2026-09-21 with every specimen anchored to its own QIIME2 profile
through the canonical specimen map; reproducible from this repository since 2026-10-01.**
The comparison was first run on 2026-05-22 and presented at the fourth doctoral tutorial.
That run paired specimens by the label column of its QIIME2 table. In the 2026-09-21
re-run, **four specimens (Au52, Au197, Au179, Au203) are re-anchored to their own QIIME2
profile** through the canonical specimen map; the other 106 carry the same counts in both
runs ([§4](#4-four-specimens-re-anchored-to-their-own-qiime2-profile)). The verdict holds
and every paired statistic rises. Both runs are archived. A self-contained report,
[`analysis/concordance_qiime2_maliampi.Rmd`](../analysis/concordance_qiime2_maliampi.Rmd),
recomputes the 2026-09-21 run from three hash-checked inputs and returns the same numbers
and the same tables, byte for byte. See [§7](#7-reproducing-it).

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
specimens and compared at four levels. Each level can fail independently:

| Question | Statistic |
|---|---|
| Does each genus vary the same way across specimens? | Spearman correlation per taxon |
| Do both pipelines call the same genera dominant in a specimen? | Jaccard index of the top-5 and top-10 |
| Are the whole abundance profiles similar, specimen by specimen? | paired Bray–Curtis dissimilarity |
| Is the global structure of the specimen space the same? | Mantel test and Procrustes on the distance matrices |

Two tracks were computed: **`genus`** (only taxa resolved to genus) and **`all_taxa`**
(also including material that could not be assigned at genus level). That way the answer
does not depend on how unassigned mass is treated. Genus names were harmonized before
matching. That curation can be switched on or off in the script, and both variants were
reported.

Every statistic above is *paired*: it compares specimen *i* in one pipeline with
specimen *i* in the other. Pairing is by label, so if a label and the counts under it come
from different specimens, nothing stops the script: the paired statistics simply measure
two different specimens against each other and come out lower. §4 describes how each
pairing is now anchored.

## 3. Result, as re-run on 2026-09-21

Values below are taken verbatim from
[`results/concordance/as_run_2026-09-21/report_curation_on.md`](../results/concordance/as_run_2026-09-21/report_curation_on.md)
(genus track, name curation enabled). The May value is shown where it differs.

| | 2026-09-21 | 2026-05-22 (pairing by label) |
|---|---|---|
| Genera reported: MaLiAmPi / QIIME2 / **shared** | 314 / 77 / **65** (63 matched directly, 2 through curation; 248 MaLiAmPi-only, 12 QIIME2-only) | same |
| Specimens compared | 110 | 110 |
| Share of each specimen's mass carried by the 65 shared genera | MaLiAmPi median **0.999** (IQR 0.997–1.000); QIIME2 median **0.996** (IQR 0.993–0.999) | same |
| Spearman per taxon | median **0.585** (IQR 0.418–0.711), n = 50 evaluable; 15 genera above 0.7, 8 below 0.3 | 0.529 (0.396–0.701); 13 above 0.7, 9 below 0.3 |
| Jaccard, top-5 genera per specimen | median **0.667** | same |
| Jaccard, top-10 genera per specimen | median **0.538** | same |
| Paired Bray–Curtis | median **0.099** (IQR 0.058–0.156) | 0.099 (0.059–0.156) |
| Mantel (Spearman) between distance matrices | **r = 0.958**, p = 0.001 | 0.940 |
| Procrustes | M² = 0.144, **correlation = 0.925**, p = 0.001 | M² = 0.159, 0.917 |

The `all_taxa` track gives the same picture: coverage 0.974 / 0.992, Spearman median
0.582, and the same per-specimen and global statistics. So the conclusion does not hinge
on unassigned mass. With curation disabled
([`report_curation_off.md`](../results/concordance/as_run_2026-09-21/report_curation_off.md))
the numbers are: Spearman median 0.544 over 46 genera, Bray–Curtis 0.062, Mantel 0.973,
Procrustes 0.959.

### Reading

- The 65 shared genera are not a fragment of the data — they carry **more than 99 % of
  the sequenced mass** in both pipelines. The comparison is about the bulk of the
  microbiome, not its tail.
- **Individual genera agree moderately** (median ρ ≈ 0.59). This is expected: the two
  pipelines use different classification algorithms and different reference databases.
  It also comes with a real warning. *Mycoplasma*, the one genus that reached FDR
  significance in the published analysis, is among the most poorly correlated
  (ρ = 0.221, 46th of 50; it was 0.248 in May). Any claim about a single taxon must be
  re-checked in both pipelines before it is carried forward.
- **Specimens agree well** (Bray–Curtis median 0.099; the top-5 genera coincide in most
  specimens).
- **The global structure agrees very well** (Mantel 0.96, Procrustes 0.93). The two
  pipelines arrange the 110 specimens in nearly the same configuration.

### Verdict

For analyses that learn from the global structure of the specimen space — which is what
the modelling framework does — **MaLiAmPi is a valid substitute for QIIME2/DADA2**, and
the next stage of the project can proceed on it. For claims about individual taxa,
agreement must be verified taxon by taxon.

The verdict is the same as in May. Re-anchoring the four specimens raised every paired
statistic.

## 4. Four specimens re-anchored to their own QIIME2 profile

### The mechanism

The May script pairs specimens **by name**. On the MaLiAmPi side it takes the column name
without its `_S##` suffix. On the QIIME2 side it takes the column `index_original` of
`genus_rel_filtered_conc_2026-03-06_abs.csv`. All 110 of those labels agree with the
canonical specimen map ([§6](#6-sample-linkage-the-canonical-map)). In **4 rows the 97
counts under the label are those of the other member of a pair**, in two pairs:

| Label in the QIIME2 table | Specimen whose counts that row holds |
|---|---|
| Au52 | Au197 |
| Au197 | Au52 |
| Au179 | Au203 |
| Au203 | Au179 |

In the May run, then, these four MaLiAmPi profiles were compared with the QIIME2 profile of
their pair partner. The other 106 rows hold their own specimen's counts, and they are
identical in both runs. The re-run takes each specimen's QIIME2 counts from the raw QIIME2
export, through the canonical map, so every row is anchored to its own specimen.

### How it was established

[`analysis/as_run/verify_sample_pairing_2026-09-21.R`](../analysis/as_run/verify_sample_pairing_2026-09-21.R),
output in
[`pairing_verification.log`](../results/concordance/as_run_2026-09-21/pairing_verification.log).
None of the tests relies on a label typed by hand:

1. **Count fingerprint.** Each of the 110 rows of the May QIIME2 input is identical,
   count for count, to exactly one specimen in the raw QIIME2 export
   (`level-6_vag138.xlsx`, rows named by QIIME2's own sample IDs). 106 match their own
   label and 4 match their pair partner.
2. **Sequencing depth.** Across the 111 specimens, the MaLiAmPi total per specimen tracks
   the sequencer's read count for the same Au### in the QC report (Spearman 0.914; the
   MaLiAmPi / raw ratio stays between 0.25 and 0.80, with no outlier). It also tracks the
   QIIME2 count for the same Au### (0.947). With the pairing the May run used, that
   second correlation drops to 0.871. For example, MaLiAmPi's Au197 has 441,632 reads and
   was paired with a QIIME2 profile of 15,515 counts, when its own profile has 63,110.
3. **Sample-sheet position.** All 111 MaLiAmPi column suffixes `_S##` equal the
   specimen's position in the sequencer's sample sheet (QC report). The MaLiAmPi side of
   the join is therefore anchored to the sequencer, not to a table.
4. **Composition.** For the four affected specimens, the paired Bray–Curtis drops from
   0.27 / 0.09 / 0.57 / 0.46 (Au52 / Au197 / Au179 / Au203, May) to 0.17 / 0.05 / 0.17 /
   0.20 against their own QIIME2 profile.

### What changed, and what did not

Only the paired statistics could change, and they all rose: median Spearman ρ 0.529 →
0.585, Mantel 0.940 → 0.958, Procrustes 0.917 → 0.925, genera above ρ 0.7 from 13 to 15.
Taxon sets, shared genera and coverage cannot depend on the pairing, and they are
identical. Most of the per-taxon change sits in rare genera (QIIME2 prevalence 3–6 %:
*Solobacterium*, *Afipia*, *Schaalia*), where a single specimen that carries the genus,
compared against another specimen's profile, is enough to move ρ. The median change per
genus is +0.004.

To make sure no other difference is mixed in, the unmodified May script was re-run on
2026-09-21 on its original input. It reproduced the archived May report and tables **byte
for byte**. The only difference between the two archived runs is therefore the four
re-anchored rows.

> **Discrepancy on record, now likely explained.** The tutorial slide reported a per-taxon
> median of 0.51, while the May report says 0.529 (curation on). The May run **with
> curation off** gives 0.506, which rounds to 0.51. The slide most likely quoted the
> curation-off variant. Both May values are superseded by 0.585 / 0.544.

## 5. What was actually run

| | |
|---|---|
| Script | [`analysis/as_run/gate_qiime2_maliampi_v3.R`](../analysis/as_run/gate_qiime2_maliampi_v3.R). It is v2 with one change: block 4a replaces the QIIME2 counts of each row with the raw QIIME2 counts of the specimen the canonical map assigns to it, and stops if any label disagrees with the map. Names, curation, seed and metrics are unchanged. Kept verbatim, absolute paths and all |
| MaLiAmPi input | `classify/tables/tallies_wide.genus.csv`, SHA-256 `2c7d208c…` (in [`metadata/maliampi_outputs_manifest.csv`](../metadata/maliampi_outputs_manifest.csv)) |
| QIIME2 counts | `level-6_vag138.xlsx`, the raw QIIME2 genus-level (level-6) export, SHA-256 `2fe59049cc79c44cccf11b92e4eaae31990fa1431a84e6e4ab270d11d8ffbafe` |
| Specimen linkage | `mapa_muestras_2026-09-20.csv`, SHA-256 `3b7e0b31…` (in the manifest; see §6) |
| QIIME2 taxon names and row labels | `genus_rel_filtered_conc_2026-03-06_abs.csv`, SHA-256 `2869dc4a99097c6a61bcde6a92b18cc64f5096b953a4622f4285046dc0bc69fe`. It is read for its column names and labels only. Its counts are replaced. It is **not** the matrix behind the published manuscript (`genus_rel_filtered_2025-05-25_abs.csv`) |
| Environment | R 4.4.2, tidyverse 2.0.0, vegan 2.7.2, patchwork 1.3.2, ggrepel 0.9.6 — recorded in [`run_curation_on.log`](../results/concordance/as_run_2026-09-21/run_curation_on.log) |
| Date | 2026-09-21. Curation on and curation off, selected with `GATE_CURACION_EXTENDIDA` |
| Outputs | [`results/concordance/as_run_2026-09-21/`](../results/concordance/as_run_2026-09-21/): two reports, per-track tables, four figures per track, the run log and the pairing verification log |
| Reproducible version | [`analysis/concordance_qiime2_maliampi.Rmd`](../analysis/concordance_qiime2_maliampi.Rmd), 2026-10-01: same numbers and tables from three hash-checked inputs (§7) |
| Superseded | [`gate_qiime2_maliampi_v2.R`](../analysis/as_run/gate_qiime2_maliampi_v2.R) → [`as_run_2026-05-22/`](../results/concordance/as_run_2026-05-22/) (pairing by label, before the four specimens were re-anchored; kept as history), and `gate_qiime2_maliampi_v1.R` before it |

## 6. Sample linkage: the canonical map

The link from a specimen (`Au###`) to a participant, visit and outcome has **one**
source: `mapa_muestras_2026-09-20.csv`. It has 111 rows, one per sequenced specimen, with
the columns `Au`, `index`, `id`, `visita`, `sdg_visita`, `desenlace_parto`,
`lecturas_crudas`, `conteos_qiime`, `conc_biblioteca_ng_ul`, `en_analisis`, `motivo`. It
was built by matching count fingerprints against the raw QIIME2 export, and checked
against the validated clinical table and the two QC reports (library concentration,
sequencing). 110 specimens are in the analysis. Au297 is excluded (328 QIIME2 counts,
below the 1,000-count filter).

- It is clinical metadata, so it is **not in this repository**. A local copy lives at
  `metadata/mapa_muestras_2026-09-20.csv` and is git-ignored. Its SHA-256
  (`3b7e0b31ce6a8634c5951eeac4cf8223adfc8c3bfe00efc51293c272d5df4c91`) is recorded in the
  output manifest, so anyone holding a copy can confirm it is this one.
- To join a MaLiAmPi table to it, strip `_S\d+$` from the column names. The suffix is the
  sample-sheet position (verified for all 111) and carries no other information.
- **Do not take the linkage from anywhere else.** In particular, not from
  `metadata_qiime.csv` (reassigns 30 of the 110 specimens;
  [`KNOWN_ISSUES.md`](../KNOWN_ISSUES.md) item 10), not from the counts of
  `genus_rel_filtered_conc_2026-03-06_abs.csv` (§4), and not from its `[BIB](ng/ul)1`
  column (item 11).

## 7. Reproducing it

[`analysis/concordance_qiime2_maliampi.Rmd`](../analysis/concordance_qiime2_maliampi.Rmd),
rendered to
[`analysis/concordance_qiime2_maliampi.html`](../analysis/concordance_qiime2_maliampi.html),
is the reproducible version of the v3 script. It has no absolute paths and no `setwd()`:
it finds the project root from its own location. It sets the seed (42) before each
Mantel test, as v3 does, and ends with `sessionInfo()`. From the repository root:

```bash
Rscript -e "rmarkdown::render('analysis/concordance_qiime2_maliampi.Rmd')"
```

### Inputs

There are three, and none of them is in the repository. Each is checked against its
recorded SHA-256 before it is read, and a mismatch stops the render. By default they are
looked for under the git-ignored `data/` and `metadata/` directories. The parameters
`maliampi_out`, `qiime2_dir` and `specimen_map` point elsewhere.

| Input | Default location | SHA-256 recorded in |
|---|---|---|
| `classify/tables/tallies_wide.genus.csv` | `data/maliampi/` | the output manifest |
| `level-6_vag138.xlsx`, the raw QIIME2 export | `data/qiime2/` | §5 above |
| `mapa_muestras_2026-09-20.csv` | `metadata/` | the output manifest |

`genus_rel_filtered_conc_2026-03-06_abs.csv` is no longer an input. v3 read only its
taxon names and row labels from it. The report takes the specimens from the canonical
map, and it derives the names from the SILVA lineages of the raw export: the last rank
that is neither empty nor `Incertae_Sedis`, bare for a genus and with its prefix
otherwise, plus `.1` for a repeated name. That rule yields the same 97 names, in the
same order.

### What it reproduces

Rendered on 2026-10-01 against the inputs above:

- **Target numbers.** In the genus track with curation on: 65 shared genera, median
  ρ 0.585, 15 genera above 0.7, Mantel 0.958, Procrustes 0.925. All five are equal.
- **Archived reports.** Every line of both tracks of `report_curation_on.md` and
  `report_curation_off.md`, regenerated with v3's own report function, is identical.
- **Archived tables.** The nine CSV tables are identical byte for byte. The four lists
  of unmatched taxa hold the same lines. Three of them are in a different order, because
  the report sorts them in C-locale order so that they do not depend on the session's
  locale.
- **Figures.** All eight are identical byte for byte.

Each of these comparisons runs inside the report, and a difference stops the render.
Outputs are written to
[`results/concordance/reproducible/`](../results/concordance/reproducible/), with the
same layout as the archived directory.

### Name curation

The report uses curation on, and states why. The SILVA release behind QIIME2 splits
*Mycoplasma* (*Mesomycoplasma*) and *Prevotella* (*Hoylesella*, *Segatella*); the NCBI
taxonomy behind MaLiAmPi does not. MaLiAmPi also has *Atopobium* where SILVA has
*Fannyhessea*. Without curation, the same organisms are compared under different names,
or not compared at all. Curation off is computed alongside, for contrast, and checked
against its own archived report.

### Still open

As far as this comparison is concerned, the QIIME2 input chain is settled: the counts
are the raw QIIME2 export's, read through the canonical map, and no decontam or
filtering touched them. What remains undocumented is how the manuscript's matrices were
derived from that export ([`KNOWN_ISSUES.md`](../KNOWN_ISSUES.md) item 7). That belongs
to the analysis compendium.

No abundance table for any participant belongs in this repository at any point in the
above; see [`DATA_ACCESS.md`](DATA_ACCESS.md).

---

| | |
|---|---|
| Written | 2026-08-30 |
| Reproducible report | 2026-10-01 |
| Pairing verified, re-run | 2026-09-21 |
| First run | 2026-05-22 |
| Reviewed by | *pending* |
