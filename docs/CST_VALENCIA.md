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

---

*Last updated 2026-10-28.*
