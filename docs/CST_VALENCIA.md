# Community state types (VALENCIA)

**The 111 specimens of the cohort were assigned VALENCIA community state types (CSTs) on
2026-05-25, from the MaLiAmPi species table. On 2026-10-28 the whole chain was re-run from
this repository with VALENCIA installed from scratch, and it gave the same input and the
same output, byte for byte.**

| CST | Specimens | of which similarity < 0.5 |
|---|---:|---:|
| I | 57 | 11 |
| II | 1 | 0 |
| III | 23 | 2 |
| IV-A | 0 | 0 |
| IV-B | 28 | 5 |
| IV-C | 1 | 0 |
| V | 1 | 0 |
| **Total** | **111** | **18** |

The counts by subCST are in [`results/valencia_cst/subcst_counts.csv`](../results/valencia_cst/subcst_counts.csv):
I-A 5, I-B 52, II 1, III-A 6, III-B 17, IV-B 28, IV-C3 1, V 1, and none in the other
five subtypes.

The assignment covers every specimen MaLiAmPi produced, including Au297, which is
excluded from the analysis set for its low QIIME2 count (328)
([`CONCORDANCE_QIIME2_MALIAMPI.md` §6](CONCORDANCE_QIIME2_MALIAMPI.md)). VALENCIA scores each
specimen on its own, so including it changes nothing for the other 110.

The same chain was applied to the DREAM Challenge's validation set on 2026-11-02:
[§6](#6-dream-validation).

---

## 1. What ran

On the WSL machine that ran MaLiAmPi (`Ubuntu-22.04`), on 2026-05-25:

| Step | What | Identified by |
|---|---|---|
| Species table | `classify/tables/tallies_wide.species.csv` from the MaLiAmPi run: 913 taxa × 111 specimens, integer read counts | SHA-256 `61c030dc…` in [`metadata/maliampi_outputs_manifest.csv`](../metadata/maliampi_outputs_manifest.csv) |
| Conversion to VALENCIA's input | [`analysis/as_run/convert_maliampi_to_valencia_2026-05-25.py`](../analysis/as_run/convert_maliampi_to_valencia_2026-05-25.py), kept exactly as it ran, run as `python3 convert_maliampi_to_valencia.py` from the home directory | SHA-256 `9c39f7a163476070767314a4f135181121a912ed7303953d87749a66622a609a`, with the CRLF line endings it was written with (`.gitattributes` keeps them). The copy that ran (`~/convert_maliampi_to_valencia.py`) and the one in the data folder on Windows are identical to it |
| VALENCIA input | `valencia_input_maliampi.csv`: 111 specimens × 409 taxa columns, plus `read_count` | SHA-256 `7388b53155aaae6af91be887ed3bdcab7477c2ce78cf1ad3dedf305325d9d082`, row `valencia/valencia_input_maliampi.csv` of the manifest |
| VALENCIA | commit **`8559d454387479f7155333693d854961463c3b15`** of `github.com/ravel-lab/VALENCIA`, in a pip virtual environment on Python 3.10.12. Pinned in commit [`20eb89b`](https://github.com/martinruhle/Mexican-PretermBirth-16S-processing/commit/20eb89bfbe7d487ff7c1a4d698c976b6fac553bc); how to install it is in [`env/VERSIONS.md`](../env/VERSIONS.md#valencia--pinned-by-its-commit-in-a-pip-virtual-environment) | |
| VALENCIA command (from the shell history) | `python3 ~/VALENCIA/Valencia.py -ref ~/VALENCIA/CST_centroids_012920.csv -i ~/valencia_input_maliampi.csv -o ~/valencia_output_maliampi -p ~/valencia_plot_maliampi` | |
| VALENCIA output | `valencia_output_maliampi.csv`: the input plus 13 similarities, `subCST`, `score` and `CST` per specimen | SHA-256 `0805b305c0bb8a85bb371794c9a23213872b65d14ebc196f4b427f23c26fac42`, row `valencia/valencia_output_maliampi.csv` of the manifest |

The input and the output hold per-specimen abundances, so they are not in this
repository. Only their hashes are. The diagnostic boxplot written with `-p` is not listed:
it does not feed the assignment.

## 2. What the conversion decides

VALENCIA expects one row per specimen, the specimen's total read count in `read_count`,
and one column per taxon, named the way its reference centroids name them. It wants
species for *Lactobacillus*, *Gardnerella*, *Prevotella*, *Atopobium* and *Sneathia*,
and genus or a higher rank (`g_Genus`, `f_Family`) for everything else. Then it divides
each column by `read_count` and compares the specimen with the 13 centroids, using only
the taxa that have a centroid column.

The converter maps each MaLiAmPi label to one VALENCIA column and adds up the reads.
The percentages below are fractions of all 28,277,142 reads in the table and come from
[`results/valencia_cst/run_valencia_cst.log`](../results/valencia_cst/run_valencia_cst.log).

| Decision | Effect on this cohort |
|---|---|
| **`read_count` is every read of the specimen**, including reads classified only above family. Those go into `unclassified_<rank>` columns, which have no centroid column. They are not dropped: they lower the specimen's similarity to every centroid | 6.82 % of reads are above family. 5.72 % are at superkingdom level alone (`superkingdom`, `superkingdom_`, `superkingdom__`) |
| ***Lactobacillus*: only crispatus, iners, gasseri and jensenii keep a species column.** A compound label that contains one of them goes to the first one in that order (`gasseri/iners` → `Lactobacillus_iners`). Everything else goes to `g_Lactobacillus`: genus-level reads, the other species, compounds without any of the four, and the *casei* group | `g_Lactobacillus` holds 1.12 % of reads, from 21 labels. Five of those species have a column of their own in the centroids that the converter does not use: *L. reuteri*, *delbrueckii*, *equicursoris*, *coleohominis* and *pontis* (0.24 % of reads together) |
| ***Gardnerella*: everything is `Gardnerella_vaginalis`**, including reads classified only to the genus | Genus-level *Gardnerella*: 0.01 % of reads |
| ***Atopobium*: only *vaginae* keeps a species column**; everything else goes to `g_Atopobium` | `g_Atopobium` is not a centroid column, so those reads count only in `read_count`. *A. parvulum* and *A. minutum* do have centroid columns but are not used (0.08 % of reads in `g_Atopobium` in total) |
| ***Prevotella* and *Sneathia*: `Genus_species` if the centroids have that column, otherwise `g_Genus`** | 13 of the 14 *Prevotella* species in the table have a centroid column; *P. salivae* (94 reads) goes to `g_Prevotella`. Both *Sneathia* species have one |
| **Other taxa**: species- and genus-level reads go to `g_<genus>`, family-level reads to `f_<family>`. A compound label is assigned to its first component | |
| **Specimen IDs**: the `_S##` suffix is removed, the same rule as the join to the canonical map | 111 unique `Au###` IDs |

How much of the cohort the centroids can see:

| | |
|---|---|
| Taxa columns with a centroid column | 108 of 409 |
| Reads in those columns | 86.73 % |
| Per specimen | median 95.04 %, minimum 37.41 %, maximum 99.74 % |
| Specimens below 80 % | 18 |
| Largest columns without a centroid column | `unclassified_superkingdom` 5.13 %, `g_Gordonia` 2.07 %, `g_Hydrotalea` 1.54 %, `unclassified_superkingdom_` 0.58 %, `unclassified_order` 0.55 % |

The similarity to the assigned subCST (VALENCIA's `score`) has a median of 0.737 and a
minimum of 0.072. 18 specimens are below 0.5, and 8 of them are also among the 18 below
80 % coverage. Those assignments are the least reliable.

## 3. Comparison with the assignment of 2026-05-25

On 2026-10-28, [`scripts/run_valencia_cst.sh`](../scripts/run_valencia_cst.sh) re-ran the
chain from this repository. It used the as-run converter unchanged, VALENCIA cloned
again at the pinned commit in a new virtual environment built from
[`env/valencia-requirements.txt`](../env/valencia-requirements.txt), and the species
table checked against the manifest. The result:

- the VALENCIA input has SHA-256 `7388b531…` and the output `0805b305…`, the same files
  as on 2026-05-25, byte for byte;
- **all 111 specimens have the same subCST**; none differs.

Nothing changed, so there is no difference to attribute. The same-day check of the
installation alone (VALENCIA on the input of 2026-05-25) is in
[`results/valencia_install_check/check_valencia_install.log`](../results/valencia_install_check/check_valencia_install.log).

One difference is in how the result was summarised, not in the result itself. The
interactive summary of 2026-05-25 grouped the CSTs by stripping the subtype from
`subCST`, so IV-B and IV-C were reported together as "IV" (29 specimens). VALENCIA's own
`CST` column, used in the table above, keeps them apart: IV-B 28 and IV-C 1. The tables
derived from that output in May for the outcome analysis, outside this repository,
carry the same subCST as the output for every specimen they hold.

## 4. Reproducing it

Install VALENCIA as [`env/VERSIONS.md`](../env/VERSIONS.md#installing-it) describes. Then,
inside WSL and from the repository root:

```bash
VALENCIA_DIR=<clone at 8559d45> VALENCIA_PY=<venv>/bin/python \
MALIAMPI_OUT=<MaLiAmPi --output directory> REFERENCE_OUTPUT=<earlier valencia_output_maliampi.csv> \
  bash scripts/run_valencia_cst.sh | tee results/valencia_cst/run_valencia_cst.log
```

The script stops unless the clone is at the pinned commit with no local changes, the
converter matches the as-run file and the species table matches the manifest. The
as-run converter reads and writes fixed paths under `~`. Rather than edit it, the script
points `HOME` at a new temporary directory with links to the MaLiAmPi output and the
VALENCIA clone. The VALENCIA input and output, and the converter's own report (which
lists specimens), stay in that directory. Only hashes and counts reach the log and
[`results/valencia_cst/`](../results/valencia_cst/). `REFERENCE_OUTPUT` is optional; with
it, the log also counts the specimens whose subCST differs from that earlier output.

## 5. What is not here

- The per-specimen assignment, and the VALENCIA input and output it comes from:
  identified by hash, held on the machine that ran it.
- CSTs by outcome, or by trimester. That is analysis, and belongs in the
  [analysis compendium](https://github.com/martinruhle/Mexican-PretermBirth-analysis).

## 6. DREAM Validation

On 2026-11-02 the same converter and the same VALENCIA assigned CSTs to the **302
specimens of the DREAM Challenge's validation set** (134 participants; Challenge project
K 159 specimens, project V 143). Only aggregates, by project, are in this repository, in
[`results/valencia_cst_dream/`](../results/valencia_cst_dream/), under the rule for
the Challenge's data in [`DATA_ACCESS.md`](DATA_ACCESS.md#what-is-committed-from-these-data).

| CST | K | of which < 0.5 | V | of which < 0.5 | Total | of which < 0.5 |
|---|---:|---:|---:|---:|---:|---:|
| I | 18 | 5 | 44 | 2 | 62 | 7 |
| II | 2 | 2 | 15 | 13 | 17 | 15 |
| III | 61 | 8 | 38 | 3 | 99 | 11 |
| IV-A | 0 | 0 | 0 | 0 | 0 | 0 |
| IV-B | 52 | 28 | 21 | 11 | 73 | 39 |
| IV-C | 20 | 16 | 11 | 7 | 31 | 23 |
| V | 6 | 2 | 14 | 3 | 20 | 5 |
| **Total** | **159** | **61** | **143** | **39** | **302** | **100** |

The counts by subCST, and how many specimens of each class agree with the Challenge's own
assignment, are in [`subcst_by_project.csv`](../results/valencia_cst_dream/subcst_by_project.csv)
and [`cst_by_project.csv`](../results/valencia_cst_dream/cst_by_project.csv).

### 6.1 What ran

| Step | What | Identified by |
|---|---|---|
| Source | `Validation.zip`, current version, of ImmPort study SDY2187, release DR61 (the files and their terms of use are in [`DATA_ACCESS.md`](DATA_ACCESS.md#dream-challenge-data-immport-sdy2187-release-dr61)). The run script stops on any other file | MD5 `ce12eec5a51d4cf7db67dfebc9850b88`, 3,231,727 bytes, identical to the DR61 manifest |
| Species table | Built by [`scripts/build_dream_species_table.py`](../scripts/build_dream_species_table.py) in MaLiAmPi's format (`tax_name`, `tax_id`, `rank`, one column per specimen): 521 rows × 302 specimens, 22,985,909 reads | SHA-256 `bc9ca38ef1c6f98f3826a286d619b5e6497be358f339573b5ce4dc43923ffd66` |
| Conversion to VALENCIA's input | The same as-run converter as the cohort's, unchanged, run with the same redirection of `HOME` (§4) | SHA-256 `9c39f7a163476070767314a4f135181121a912ed7303953d87749a66622a609a` |
| VALENCIA input | 302 specimens × 259 taxa columns, plus `read_count` | SHA-256 `b926a0ebfe89dcc8d7b8fb32fb9cd171b9a9722b9e7a553049f9144e7648a269` |
| VALENCIA | Commit **`8559d454387479f7155333693d854961463c3b15`**, centroids `CST_centroids_012920.csv` (SHA-256 `9d184567…`), in the virtual environment that assigned the cohort, whose `pip freeze` is [`env/valencia-requirements.txt`](../env/valencia-requirements.txt) plus scipy, which neither script imports ([`env/VERSIONS.md`](../env/VERSIONS.md#valencia--pinned-by-its-commit-in-a-pip-virtual-environment)) | |
| VALENCIA output | The input plus 13 similarities, `subCST`, `score` and `CST` per specimen | SHA-256 `7f7a69b0ac7cb78a8146944b761649c8ece8ae45d8e79f7cb707ba625f5abcd0` |

**Why the species table is rebuilt.** The Challenge distributes its taxonomy tables with
specimens as rows and the taxon name as the only column label: no `tax_id` and no `rank`,
which the converter reads. Both come from two other files of the same archive.
`sv_counts/sp_sv_long.csv` gives the reads per specimen and sequence variant;
`taxonomy/sv_taxonomy.csv`, at `want_rank` = species, gives each variant's label, tax_id and
rank (365 of its 2,724 species-level rows have an empty `sv` and are left out). The table
is accepted only if two checks pass, and both did:

- summed by `tax_name`, it is **equal cell by cell to `taxonomy/taxonomy_nreads.species.full.csv`**
  (302 specimens × 521 labels);
- every specimen's column sums to its `total_reads` in `sp_sv_long.csv`.

281 (specimen, variant) pairs, in 25 specimens of project V, appear on more than one row of
`sp_sv_long.csv`. `total_reads` counts every row, so the rows are added; the first check
shows that the Challenge's own table adds them too.

The tables without `.full` in their name, `taxonomy_nreads.species.csv` and the `relabd`
tables that are not `.full`, are not used: they lack 21 of the labels and 194,303 of the
reads of the `.full` table.

### 6.2 Agreement with the CST the Challenge distributes

The archive includes the Challenge's own VALENCIA assignment
(`community_state_types/cst_valencia.csv`, SHA-256 `7fcd8bff…`).

| | K (159) | V (143) | Total (302) |
|---|---:|---:|---:|
| Same CST as the Challenge's | 125 (78.6 %) | 135 (94.4 %) | 260 (86.1 %) |
| Same subCST | 123 (77.4 %) | 133 (93.0 %) | 256 (84.8 %) |
| Similarity < 0.5, this run | 61 (38.4 %) | 39 (27.3 %) | 100 (33.1 %) |
| Similarity < 0.5, the Challenge's assignment | 85 (53.5 %) | 45 (31.5 %) | 130 (43.0 %) |

Most disagreements involve CST IV-C. This run puts 31 specimens there; the Challenge puts
7 of them in IV-C too, and 12 in IV-B. The Challenge's assignment uses no IV-C subtype
other than IV-C0, while this run gives IV-C1, IV-C3 or IV-C4 to 15 specimens. The full
cross-tabulation, by project, is in
[`cst_vs_dream_by_project.csv`](../results/valencia_cst_dream/cst_vs_dream_by_project.csv).

The Challenge built its VALENCIA input with a conversion of its own: its input table
(`cst_valencia_w_taxons.csv`) has a column set that differs from the converter's, for
example a `Lactobacillus_johnsonii` column, which the centroids do not have. Which VALENCIA
version it ran is not recorded in any file of the archive. The agreement therefore measures both
conversions together, not VALENCIA alone.

### 6.3 What is the same as for the cohort, and what is not harmonized

**The same:** the converter (SHA-256 `9c39f7a1…`), VALENCIA (commit `8559d45`) and its
centroids.

**Not harmonized:** the classification the conversion starts from. The labels are the
Challenge's: its own reference package, its own denoising run and its own sequencing, which
may cover a different variable region than the cohort's V3–V4. The validation variants'
sequences are not distributed
([`NEXT_STAGE_DREAM_REFPKG.md` §3b](NEXT_STAGE_DREAM_REFPKG.md)), so none of this can be
redone here. A comparison of CSTs between the cohort and DREAM Validation compares **the
same conversion applied to two different classifications**.

The converter's decisions (§2) weigh differently on this set. Percentages are fractions of
the 22,985,909 reads (the log's line "fraction of all reads in the cohort" comes from the
unchanged summary script; here it means the validation set):

| Decision | Effect on DREAM Validation | On the cohort |
|---|---|---|
| ***L. johnsonii* goes to `g_Lactobacillus`.** Only crispatus, iners, gasseri and jensenii keep a column, and CST II is defined by *L. gasseri*. The compound `Lactobacillus gasseri/johnsonii` goes to `Lactobacillus_gasseri` | `g_Lactobacillus` holds 10.15 % of reads. *L. johnsonii* alone is 7.89 %: 9.16 % of project V and 2.14 % of K. It is the label with the most reads in 14 of the 143 V specimens and 4 of the 159 K specimens. The compound holds 0.15 % | `g_Lactobacillus` 1.12 %. The three labels that contain *johnsonii* hold 1,058 of 28,277,142 reads, and none is the main label of any specimen |
| Five *Lactobacillus* species with a centroid column of their own go to `g_Lactobacillus` | *L. coleohominis*, *delbrueckii*, *fermentum*, *reuteri*, *salivarius*: 0.99 % | *L. reuteri*, *delbrueckii*, *equicursoris*, *coleohominis*, *pontis*: 0.24 % |
| **BVAB1** has a centroid column, but no Challenge label names it. Family-level *Lachnospiraceae* goes to `f_Lachnospiraceae` | `f_Lachnospiraceae` holds 2.08 % of reads (K 5.67 %, V 1.29 %). Any BVAB1 reads in the set are among them | |
| Ranks above family go to `unclassified_<rank>`, named after the rank as written (`class_` → `unclassified_class_`) | 0.86 % of reads; 0.15 % at superkingdom level | 6.82 %; 5.72 % at superkingdom level |

How much of the set the centroids can see: 114 of 259 taxa columns, holding 97.25 % of
reads. Per specimen, the median is 99.78 % and the minimum 0.33 %; 11 specimens are below
80 %, and 7 of them are also below 0.5 similarity.

A sensitivity analysis that sends *L. johnsonii* to `Lactobacillus_gasseri` was **not
run**. If it is added, it is a separate converter, written down before it runs, and the
as-run converter stays as it is.

### 6.4 Reproducing it, and where the per-specimen files are

Inside WSL, from the repository root, with VALENCIA installed as in §4:

```bash
VALENCIA_DIR=<clone at 8559d45> VALENCIA_PY=<venv>/bin/python \
VALIDATION_ZIP=<Validation.zip, current version> KEEP_DIR=<directory outside the repository> \
  bash scripts/run_valencia_cst_dream.sh | tee results/valencia_cst_dream/run_valencia_cst_dream.log
```

[`scripts/run_valencia_cst.sh`](../scripts/run_valencia_cst.sh) stops on any species
table other than the cohort's, so the Validation set has a script of its own,
[`scripts/run_valencia_cst_dream.sh`](../scripts/run_valencia_cst_dream.sh). It checks the
VALENCIA commit, the converter's SHA-256 and the archive's MD5, builds the species table,
and runs the converter, VALENCIA,
[`scripts/summarise_valencia_cst.py`](../scripts/summarise_valencia_cst.py) (unchanged,
on the whole set; its `--compare` reads a copy of the Challenge's assignment with the
`specimen` column renamed `sampleID`) and
[`scripts/summarise_valencia_cst_dream.py`](../scripts/summarise_valencia_cst_dream.py)
(by project, and against the Challenge's CST).

The species table, the VALENCIA input and output, and the specimen-to-project list hold
per-specimen data. They are copied to `KEEP_DIR`, a stable local directory outside the
repository (on the WSL machine, `~/valencia_cst_dream/`), for later work that needs the
per-specimen CST. They are identified by the SHA-256 sums printed in the log,
[`results/valencia_cst_dream/run_valencia_cst_dream.log`](../results/valencia_cst_dream/run_valencia_cst_dream.log).

---

*Last updated 2026-11-02.*
