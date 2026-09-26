# Provenance of the reference package used by our MaLiAmPi run

**Question.** Did our MaLiAmPi run place the amplicon sequence variants against the
public reference package distributed with the Microbiome Preterm Birth DREAM
Challenge, or against a reference package that we built ourselves?

**Answer. We built it ourselves.** The reference package was constructed during our
own run, on 2026-02-18, from a local copy of an ARF sequence repository. No
externally distributed reference package was supplied to the workflow.

Everything below can be re-checked from the files listed in the *Where to verify*
column, without access to the sequencing reads.

---

## 1. The evidence

| # | Observation | Where to verify |
|---|---|---|
| 1 | The launch command supplied **`--repo_fasta`, `--repo_si` and `--taxdmp`** — a repository of reference sequences, its sequence-info table, and an NCBI taxonomy dump. These are build inputs. No pre-built reference package was passed on the command line; grepping every `--` flag in the Nextflow log yields exactly `--manifest --output --email --repo_fasta --repo_si --taxdmp` (plus internal `--seq`/`--outfile`). | [`logs/maliampi_launch_command.txt`](../logs/maliampi_launch_command.txt) |
| 2 | The **reference-package-building sub-workflow ran end to end**: `RefpkgSearchRepo → FilterSeqInfo → BuildTaxtasticDB → ConfirmSI → RemoveDroppedRecruits → CombinedRefFilter → AlignRepoRecruits → ConvertAlnToFasta → TaxtableForSI → RaxmlTree → RaxmlTree_cleanupInfo → CombineRefpkg_og`. Those twelve processes exist to construct a reference package; a run that consumed a ready-made one would not execute them. | [`logs/maliampi_refpkg_build_processes.txt`](../logs/maliampi_refpkg_build_processes.txt) |
| 3 | The reference package carries **its own build timestamp**: `metadata.create_date = 2026-02-18 01:11:21`, with an internal log reading `Loaded initial files into empty refpkg` → `Stripped refpkg (removed 0 files)` → `Rerooted`. It was assembled from scratch, not unpacked from a distribution. | [`metadata/refpkg_CONTENTS.json`](../metadata/refpkg_CONTENTS.json) |
| 4 | The **phylogeny inside it was inferred during the run**, by RAxML 8.2.4 on an alignment of 2,936 distinct patterns (65.12 % gaps/undetermined), GTRGAMMA, one inference from a randomized MP starting tree, fixed seed (`raxmlHPC-PTHREADS-AVX2 -n refpkg -m GTRGAMMA -s recruits.aln.fasta -p 12345 -T 1`). | [`metadata/refpkg_RAxML_info.txt`](../metadata/refpkg_RAxML_info.txt) |
| 5 | The reference sequences came from the **ARF release `arf_20200420`**, downloaded from Zenodo (<https://zenodo.org/records/6876634>) and unpacked at `~/arf_20200420/dedup/1200bp/named/filtered/` — full-length, deduplicated, named and outlier-filtered 16S records. Their `download_date` values span **2019-07-12 to 2020-05-04**, consistent with that release. | `references_seq_info.csv` inside the reference package; regenerate with `scripts/describe_refpkg.R` |

### Identity of the artifact

| Field | Value |
|---|---|
| File | `refpkg/refpkg.tar.gz` in the MaLiAmPi output directory |
| Size | 6,117,378 bytes |
| **SHA-256** | `2a3ce022576744c0c0bd858f005db52ab2c27e6ec249a55c56ef3e9c87622b2e` |
| Build date | 2026-02-18 01:11:21 (from `CONTENTS.json`) |
| Format | taxtastic reference package, format version 1.1, locus 16S |

The SHA-256 above is also the row for `refpkg/refpkg.tar.gz` in
[`metadata/maliampi_outputs_manifest.csv`](../metadata/maliampi_outputs_manifest.csv),
and the per-file MD5 sums recorded by taxtastic itself are in
[`metadata/refpkg_CONTENTS.json`](../metadata/refpkg_CONTENTS.json). Any copy of this
reference package can be checked against both.

---

## 2. What is inside the reference package

Measured directly from the archive (see `scripts/describe_refpkg.R`):

| Property | Value |
|---|---|
| Reference sequences | 5,540 |
| Sequence length | 1,200–1,592 bp (median 1,425) |
| Distinct species names | 1,231 |
| Distinct genus names | 456 |
| Taxonomy table | 2,553 nodes (1,231 at rank `species`, 455 at rank `genus`) |
| Tree | `treeckq22_gn.tre`, rerooted; RAxML best tree kept as rollback |
| Covariance model | `SSU_rRNA_bacteria.cm` |

---

## 3. Why this matters

MaLiAmPi does not classify a sequence by similarity against a database; it *places*
the sequence on the reference phylogeny and reads the taxonomy off its position.
Two consequences follow directly from the answer above.

1. **Taxonomic tables are still comparable across reference packages**, because a
   genus or species name means the same thing regardless of which tree produced it.
   That is what made the QIIME2 ↔ MaLiAmPi genus-level concordance analysis possible
   (see [`docs/CONCORDANCE_QIIME2_MALIAMPI.md`](CONCORDANCE_QIIME2_MALIAMPI.md)).
2. **Phylotypes are not.** A phylotype is a bin of placements on the reference tree
   at a chosen phylogenetic distance; its identity is defined by the tree it was cut
   from. Phylotypes produced against our own reference package therefore cannot be
   matched, one to one, against the phylotypes distributed by the DREAM Challenge,
   which were produced against theirs.

Point 2 is the reason the next stage of this repository exists: to re-run placement
against the DREAM reference package so that our cohort and the DREAM cohorts live in
the same phylotype space. See
[`docs/NEXT_STAGE_DREAM_REFPKG.md`](NEXT_STAGE_DREAM_REFPKG.md).

---

## 4. What would overturn this conclusion

Stated so that a reviewer can attack it rather than take it on trust:

- **If the DREAM Challenge built its own reference package from the same ARF release**,
  then ours and theirs would share their input sequences and differ only in the tree
  inference run. The conclusion "we built it" would still hold, but the practical
  distance between the two packages would be much smaller than it looks, and
  re-placement might buy less than expected. Our side of this is now settled — the
  sequences came from `arf_20200420` on Zenodo (evidence 5) — but **what the Challenge
  used is not established**, and cannot be until their reference package, or a
  description of it, is in hand. That is task 2 of the next stage.
- **If a reference package had been supplied through a configuration file** rather
  than the command line, the `--` flags above would not show it. Against this: the
  build sub-workflow ran (evidence 2) and the artifact carries a fresh build date
  (evidence 3), neither of which is consistent with consuming a ready-made package.
  **Checked on 2026-09-24, on the machine that ran:** the workflow version used (tag
  `v3.5.0`) has no parameter for a ready-made package at all — `main.nf` always calls
  the build sub-workflow; the only configuration in effect,
  [`env/nextflow.config`](../env/nextflow.config), holds process resources and Docker
  options and nothing else; and no session passed `-c`. There was no channel through
  which a package could have been supplied.

The second check is done. The first waits on the DREAM Challenge's reference package,
which is not published anywhere we could find
([`NEXT_STAGE_DREAM_REFPKG.md` §3b](NEXT_STAGE_DREAM_REFPKG.md)).

---

## 5. Status of this document

| | |
|---|---|
| Written | 2026-08-30 |
| §4, second check completed | 2026-09-26, from evidence gathered on the machine that ran on 2026-09-24 |
| Based on | the MaLiAmPi run completed 2026-02-18 12:00:03 (`logs/maliampi_run_summary_2026-02-18.txt`) |
| Reviewed by | *pending* |

The run itself, its parameters and its outputs are documented in
[`docs/RUN_MALIAMPI.md`](RUN_MALIAMPI.md).
