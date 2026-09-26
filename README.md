# Mexican-PretermBirth-16S-processing

**How the 16S sequencing data of the Mexican preterm birth cohort were turned into
abundance tables — what was run, against what, with which software, and what came out.**

This repository is the upstream half of a two-repository project:

| | |
|---|---|
| **This repository** | from FASTQ reads to taxon × specimen tables: MaLiAmPi, its reference package, the phylogenetic placements, and the check that this pipeline agrees with the earlier QIIME2 one |
| [**Mexican-PretermBirth-analysis**](https://github.com/martinruhle/Mexican-PretermBirth-analysis) | from those tables to the models: nested cross-validation, feature selection, the published results |

They are separate because they are different machines' worth of software. The analysis
compendium is an R package with a frozen `renv` lockfile and a test suite that runs in
minutes; this one is a Nextflow pipeline in Docker containers that accumulated 970 CPU
hours. Putting both in one repository would mean neither environment could be pinned
cleanly.

---

## Start here

| If you want to know… | Read |
|---|---|
| **How to run MaLiAmPi on a laptop without it dying** | [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md) |
| Which reference package our placements were made against, and how we know | [`docs/REFPKG_PROVENANCE.md`](docs/REFPKG_PROVENANCE.md) |
| What exactly was run, on what, with what, and what it produced | [`docs/RUN_MALIAMPI.md`](docs/RUN_MALIAMPI.md) |
| Whether MaLiAmPi and QIIME2 see the same microbiome | [`docs/CONCORDANCE_QIIME2_MALIAMPI.md`](docs/CONCORDANCE_QIIME2_MALIAMPI.md) |
| What comes next and why it has not happened yet | [`docs/NEXT_STAGE_DREAM_REFPKG.md`](docs/NEXT_STAGE_DREAM_REFPKG.md) |
| What is still unresolved about this run | [`KNOWN_ISSUES.md`](KNOWN_ISSUES.md) |
| Where the actual data is, since it is not here | [`docs/DATA_ACCESS.md`](docs/DATA_ACCESS.md) |
| Which software versions are pinned, and which are not yet | [`env/VERSIONS.md`](env/VERSIONS.md) |

---

## The three findings so far

**1. The reference package is ours, not the DREAM Challenge's.**
The run passed `--repo_fasta` / `--repo_si` / `--taxdmp`, the twelve processes of the
reference-package-building sub-workflow executed, and the resulting package carries its
own build date of 2026-02-18 01:11:21. It holds 5,540 reference sequences (1,231
species, 456 genera) on a tree inferred by RAxML 8.2.4 during the run.
SHA-256 `2a3ce022576744c0c0bd858f005db52ab2c27e6ec249a55c56ef3e9c87622b2e`.
Full evidence and the checks that would overturn it: [`docs/REFPKG_PROVENANCE.md`](docs/REFPKG_PROVENANCE.md).

**2. MaLiAmPi resolves the cohort far more finely than QIIME2 did.**
547 genera and 913 species across 111 specimens, from 21,382 sequence variants — against
the 77 genera in the QIIME2 table used for the comparison.

**3. The two pipelines describe the same microbiome where it matters.**
The 65 genera both pipelines report carry over 99 % of the sequenced mass in each.
Global structure agrees closely (Mantel 0.958, Procrustes 0.925, both p = 0.001) and
specimens agree well (paired Bray–Curtis median 0.099). Individual genera agree only
moderately (median Spearman ρ = 0.585). *Mycoplasma*, the one genus that reached FDR
significance in the published analysis, is among the worst (ρ = 0.221), so single-taxon
claims must be re-checked in both pipelines before being carried forward.
These are the 2026-09-21 figures, from a re-run in which every specimen is anchored to
its own QIIME2 profile through the canonical specimen map. Relative to the first run
(2026-05-22), four specimens (Au52, Au197, Au179, Au203) are re-anchored, which moves
median ρ from 0.529, Mantel from 0.940 and Procrustes from 0.917 to the values above
([`docs/CONCORDANCE_QIIME2_MALIAMPI.md` §4](docs/CONCORDANCE_QIIME2_MALIAMPI.md)).

---

## Status

| Stage | State |
|---|---|
| MaLiAmPi run on the Mexican cohort | ✅ complete (2026-02-18), documented here |
| Provenance of the reference package | ✅ established |
| Specimen ↔ participant linkage | ✅ one canonical map, identified by SHA-256; every MaLiAmPi ↔ QIIME2 pairing verified (2026-09-21) — [`docs/CONCORDANCE_QIIME2_MALIAMPI.md` §6](docs/CONCORDANCE_QIIME2_MALIAMPI.md) |
| QIIME2 ↔ MaLiAmPi concordance | ⚠️ re-run and archived, **not yet reproducible from this repository** — see [`docs/CONCORDANCE_QIIME2_MALIAMPI.md` §7](docs/CONCORDANCE_QIIME2_MALIAMPI.md) |
| Software environment for the downstream tooling | ⚠️ partially pinned — [`env/VERSIONS.md`](env/VERSIONS.md) |
| Phylotype binning (0.1 / 0.5 / 1.0) | 🚧 not started |
| **Re-placement against the DREAM Challenge reference package** | 🚧 **not started** — [`docs/NEXT_STAGE_DREAM_REFPKG.md`](docs/NEXT_STAGE_DREAM_REFPKG.md) |
| External validation against the DREAM hispanic subgroup | 🚧 blocked on the two rows above |

Nothing in this repository is written as if a pending stage were done. Where a result
was produced but cannot yet be re-run from here, it says so at the point where the
result is quoted.

Two gaps are worth knowing before you rely on anything: the exact command of the
successful run has not been recovered, and the local `main.nf` patch is described but not
committed. Both are in [`KNOWN_ISSUES.md`](KNOWN_ISSUES.md), along with six more open ones.

---

## Layout

```
docs/            what was run and what it means; one document per question
KNOWN_ISSUES.md  what is still unresolved
env/             the Nextflow profile and host configuration that were in effect
workflow/        pipeline invocation, manifest format, and the local patch it needs
scripts/         small tools: describe a reference package, checksum the outputs
metadata/        checksums and manifests — small files that identify the large ones
analysis/        as_run/ = scripts exactly as executed; reproducible reports land here
results/         aggregated outputs (no participant-level abundances)
logs/            verbatim excerpts of the run logs, kept as evidence
```

## Reproducing versus checking

Reproducing the run needs the reads, the reference repository and about a thousand CPU
hours. Checking that you hold the same artifacts it produced takes two commands:

```bash
Rscript scripts/describe_refpkg.R /path/to/refpkg.tar.gz
```

```bash
MALIAMPI_OUT=/path/to/salida_analisis bash scripts/make_output_manifest.sh
git diff metadata/maliampi_outputs_manifest.csv
```

An empty diff means the outputs are identical to the ones every document here describes.

## What is deliberately absent

No FASTQ files, no classification database, no taxon × specimen abundance table for any
participant, at any rank. This repository describes and identifies those files; it does
not distribute them. Raw reads are in SRA under BioProject **PRJNA1440471**. See
[`docs/DATA_ACCESS.md`](docs/DATA_ACCESS.md).

---

## Software used

- **MaLiAmPi** — Golob JL. *MaLiAmPi: Maximum Likelihood Amplicon Pipeline.*
  <https://github.com/jgolob/maliampi>
- **The Microbiome Preterm Birth DREAM Challenge** — Golob JL, Oskotsky TT, Tang AS,
  et al. *Cell Reports Medicine* 2024;5(1):101359. The benchmark this project aims to
  be comparable with.

## Citation

See [`CITATION.cff`](CITATION.cff). The published analysis this processing supports is
cited in the [analysis compendium](https://github.com/martinruhle/Mexican-PretermBirth-analysis).

Licensed MIT — see [`LICENSE`](LICENSE).

---

*Last updated 2026-09-21.*
