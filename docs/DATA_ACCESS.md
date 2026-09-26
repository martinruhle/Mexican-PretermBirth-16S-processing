# Where the data lives

This repository is a **provenance record**, not a data archive. It holds the
description of how the 16S data for the Mexican preterm birth cohort were processed,
together with checksums that identify the files involved. It does not hold the files
themselves.

## What is here

| | |
|---|---|
| Run records, parameters, environment | `docs/`, `env/`, `workflow/`, `logs/` |
| Checksums and dimensions of every MaLiAmPi output | [`metadata/maliampi_outputs_manifest.csv`](../metadata/maliampi_outputs_manifest.csv) |
| Reference package metadata (taxtastic `CONTENTS.json`, RAxML info, summary) | `metadata/` |
| Aggregated results of the QIIME2 ↔ MaLiAmPi comparison | [`results/concordance/`](../results/concordance/) — per-taxon correlations, per-specimen distances, figures |
| The script as it was actually run | [`analysis/as_run/`](../analysis/as_run/) |

## What is not here, and where to find it

| | |
|---|---|
| **Raw 16S reads (FASTQ)** | NCBI Sequence Read Archive, BioProject **PRJNA1440471** |
| **MaLiAmPi outputs** (sequence variants, placements, classification database, taxon × specimen tables) | Roughly 1.3 GB, regenerable from the reads with [`workflow/run_maliampi.sh`](../workflow/run_maliampi.sh). Identified by SHA-256 in `metadata/maliampi_outputs_manifest.csv` |
| **The reference package** (`refpkg.tar.gz`, 6.1 MB) | Produced by the same run; SHA-256 `2a3ce022576744c0c0bd858f005db52ab2c27e6ec249a55c56ef3e9c87622b2e`. See [`REFPKG_PROVENANCE.md`](REFPKG_PROVENANCE.md) |
| **QIIME2 genus tables and clinical metadata** | The analysis compendium, [`Mexican-PretermBirth-analysis`](https://github.com/martinruhle/Mexican-PretermBirth-analysis), and its own `docs/DATA_ACCESS.md` |
| **The canonical specimen ↔ participant map** (`mapa_muestras_2026-09-20.csv`, 111 rows) | Held with the clinical metadata. Identified here by SHA-256 `3b7e0b31ce6a8634c5951eeac4cf8223adfc8c3bfe00efc51293c272d5df4c91` in [`metadata/maliampi_outputs_manifest.csv`](../metadata/maliampi_outputs_manifest.csv); a local copy under `metadata/` is git-ignored. See [`CONCORDANCE_QIIME2_MALIAMPI.md` §6](CONCORDANCE_QIIME2_MALIAMPI.md) |
| **ARF reference sequence repository** (release `arf_20200420`) | Zenodo, <https://zenodo.org/records/6876634>. The archive as downloaded (`arf_20200420.tgz`, 998,142,756 bytes) and its unpacked copy (`~/arf_20200420/`) are on the machine that ran the pipeline. The release is identified in [`REFPKG_PROVENANCE.md` §1, evidence 5](REFPKG_PROVENANCE.md): the `download_date` values of the sequences inside our reference package span 2019-07-12 to 2020-05-04, consistent with that release |

## The rule this repository follows

No per-participant abundance table is committed here, at any taxonomic rank, in any
form. What is committed is enough to *identify* those tables — filenames, sizes,
SHA-256 sums, dimensions — so that two people can confirm they are holding the same
data without either of them publishing it.

Aggregated results are a different matter and are committed: a correlation per genus,
a distance per specimen, a figure. None of them can be inverted back into an abundance
profile.

## Getting access

The cohort is coordinated at the Instituto Nacional de Perinatología, Mexico City.
Requests for material beyond what is in SRA go through the study team; see the
corresponding section of the analysis compendium, which is the repository cited in the
published article's data availability statement.

---

*Last updated 2026-09-26.*
