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
| Counts of specimens per VALENCIA community state type, and the log of the run that produced them | [`results/valencia_cst/`](../results/valencia_cst/) — see [`CST_VALENCIA.md`](CST_VALENCIA.md) |
| The same counts for DREAM Validation, by Challenge project, with their agreement with the Challenge's own assignment | [`results/valencia_cst_dream/`](../results/valencia_cst_dream/) — see [`CST_VALENCIA.md` §6](CST_VALENCIA.md#6-dream-validation) |
| The scripts as they were actually run | [`analysis/as_run/`](../analysis/as_run/) |

## What is not here, and where to find it

| | |
|---|---|
| **Raw 16S reads (FASTQ)** | NCBI Sequence Read Archive, BioProject **PRJNA1440471** |
| **MaLiAmPi outputs** (sequence variants, placements, classification database, taxon × specimen tables) | Roughly 1.3 GB, regenerable from the reads with [`workflow/run_maliampi.sh`](../workflow/run_maliampi.sh). Identified by SHA-256 in `metadata/maliampi_outputs_manifest.csv` |
| **The reference package** (`refpkg.tar.gz`, 6.1 MB) | Produced by the same run; SHA-256 `2a3ce022576744c0c0bd858f005db52ab2c27e6ec249a55c56ef3e9c87622b2e`. See [`REFPKG_PROVENANCE.md`](REFPKG_PROVENANCE.md) |
| **QIIME2 genus tables and clinical metadata** | The analysis compendium, [`Mexican-PretermBirth-analysis`](https://github.com/martinruhle/Mexican-PretermBirth-analysis), and its own `docs/DATA_ACCESS.md` |
| **The canonical specimen ↔ participant map** (`mapa_muestras_2026-09-20.csv`, 111 rows) | Held with the clinical metadata. Identified here by SHA-256 `3b7e0b31ce6a8634c5951eeac4cf8223adfc8c3bfe00efc51293c272d5df4c91` in [`metadata/maliampi_outputs_manifest.csv`](../metadata/maliampi_outputs_manifest.csv); a local copy under `metadata/` is git-ignored. See [`CONCORDANCE_QIIME2_MALIAMPI.md` §6](CONCORDANCE_QIIME2_MALIAMPI.md) |
| **VALENCIA input and output** (`valencia_input_maliampi.csv`, `valencia_output_maliampi.csv`: per-specimen abundances and CST) | On the machine that ran the pipeline. Identified by SHA-256 in `metadata/maliampi_outputs_manifest.csv` (rows `valencia/`), and regenerable from the species table with [`scripts/run_valencia_cst.sh`](../scripts/run_valencia_cst.sh). See [`CST_VALENCIA.md`](CST_VALENCIA.md) |
| **ARF reference sequence repository** (release `arf_20200420`) | Zenodo, <https://zenodo.org/records/6876634>. The archive as downloaded (`arf_20200420.tgz`, 998,142,756 bytes) and its unpacked copy (`~/arf_20200420/`) are on the machine that ran the pipeline. The release is identified in [`REFPKG_PROVENANCE.md` §1, evidence 5](REFPKG_PROVENANCE.md): the `download_date` values of the sequences inside our reference package span 2019-07-12 to 2020-05-04, consistent with that release |
| **DREAM Challenge data** (ImmPort study SDY2187, release DR61) | ImmPort, behind a free login. Identified file by file in the next section |

## DREAM Challenge data (ImmPort SDY2187, release DR61)

Some results in this repository are computed on the data of the Microbiome Preterm Birth
DREAM Challenge. They come from **ImmPort study SDY2187**, "Microbiome Preterm Birth DREAM
Challenge: Crowdsourcing Machine Learning Approaches to Advance Preterm Birth Research"
(sponsor: March of Dimes; DOI [10.21430/M3JMMPMLSP](https://doi.org/10.21430/M3JMMPMLSP);
study page <https://www.immport.org/shared/study/SDY2187>), **release DR61** (2026-02-26),
which is the deposit the Challenge article points to in its data availability statement
(see [`NEXT_STAGE_DREAM_REFPKG.md` §3b](NEXT_STAGE_DREAM_REFPKG.md)).

### The files

Local copies are held outside this repository. Each MD5 below was computed on the local
copy on 2026-11-02 and is identical to the one in the release manifest
(`SDY2187-DR61_manifest.txt`, which came in the study's metadata package downloaded on
2026-09-24, `immport_SDY2187_20260924_1637.zip`, SHA-256 `a589ff99bad3626188a3f3df626a2f85155fc60f3e1759eb482256d201823908`).

| File | ImmPort entry | Bytes | MD5 | Used for |
|---|---|---:|---|---|
| `Validation.zip`, current version ("Updated version: 12/13/2024"; dated 2025-01-09 on the study-files page) | study file `SFL72960` | 3,231,727 | `ce12eec5a51d4cf7db67dfebc9850b88` | Taxonomy tables and metadata of the validation set |
| `IDmapping_participantID_ImmPortSUBacc.txt` | study file `SFL25612` | 13,016 | `ab6a354be7675389e051f2c9f5685d9c` | Links each Challenge `participant_id` to its ImmPort subject accession |
| `SDY2187-DR61_Tab.zip` | release artifact | 410,485 | `88bd8f6f292ac48666abe4b704c35c06` | ImmPort's own tables for the study; among them `Tab/subject.txt` (64,660 bytes, MD5 `bc83474674bfd5b8ef21bd8f031e5f9c`; not listed in the manifest, which hashes the archive only) |

Two more files were opened to write [`NEXT_STAGE_DREAM_REFPKG.md` §3b](NEXT_STAGE_DREAM_REFPKG.md),
and no committed result is derived from either: `Training.zip` (study file `SFL25545`,
47,085,449 bytes, MD5 `cfed9839b8636352c910789fe5757863`, identical to the manifest) and
the earlier `Validation.zip` (dated 2023-11-30, 3,694,119 bytes, MD5
`d21489d51cce74d4672a9ec3aaae6d91`), which the current version replaced and the DR61
manifest no longer lists. Any result computed on validation data uses the current version.

### These are ImmPort's copies, not the Challenge's

The Challenge itself distributed its data through Synapse (`syn26133770`), and those data
were released [for use within the Challenge only][synapse-terms], to be destroyed when it
ended. The files above are not that download: they are the later public deposit in ImmPort,
obtained from the SDY2187 study page with an ImmPort login, and they are used under
ImmPort's terms.

### ImmPort's terms of use

[User Agreement for the NIAID Immunology Database and Analysis Portal][immport-terms]
(<https://www.immport.org/agreement>, which resolves to
<https://docs.immport.org/home/agreement/>), **read on 2026-11-02**. The clauses that bear
on this repository:

- **§1.1** — the data may not be used, alone or with other data, to identify any individual
  or to link these data with another dataset in a way that includes anyone's identity.
- **§2.4** — the data provider keeps ownership; the data may be used for any legal purpose
  and redistributed, provided that any redistribution happens under terms commensurate with
  the agreement.
- **§3.2.3** — publications and presentations that use the data acknowledge ImmPort and the
  data providers, citing the study accession and title (SDY2187, above) and ImmPort itself
  (Bhattacharya et al. 2018, *Sci Data* 5:180015, [10.1038/sdata.2018.15](https://doi.org/10.1038/sdata.2018.15)).

### Where ethnicity comes from

The current `Validation.zip` has no ethnicity column in `metadata/metadata.csv`. Ethnicity is
taken from the `ETHNICITY` column of `subject.txt`, joined to the Challenge's
`participant_id` through `IDmapping_participantID_ImmPortSUBacc.txt`. The same Validation
archive carries a second, independent copy in `metadata/metadata_normalized.csv`, as two
indicator columns (`Ethnicity: Hispanic or Latino`, written `True`/`False`, and
`Ethnicity: Unknown`, written `0`/`1`), and it serves as a control: on 2026-11-02 the two
sources agreed on **302 of 302 specimens** (134 participants: 38 "Hispanic or Latino",
95 "Not Hispanic or Latino", 1 "Not Specified").

### What is committed from these data

The rule of the next section applies to the Challenge's data with no exception, and more
strictly: from the DREAM data, **only aggregates are committed** — counts of specimens or
participants per community state type, subtype or group, fractions, and the hashes that
identify inputs and outputs. **Never** a row per specimen or per participant, a Challenge or
ImmPort identifier, anyone's individual ethnicity, or the ID mapping. Per-specimen outputs,
where a later step needs them, stay outside the repository, identified here by SHA-256
(for the VALENCIA assignment of the validation set, in
[`CST_VALENCIA.md` §6.4](CST_VALENCIA.md#64-reproducing-it-and-where-the-per-specimen-files-are)).

[synapse-terms]: https://repo-prod.prod.sagebase.org/repo/v1/entity/syn26133770/wiki/618022
[immport-terms]: https://docs.immport.org/home/agreement/

## The rule this repository follows

No per-participant abundance table is committed here, at any taxonomic rank, in any
form. What is committed is enough to *identify* those tables — filenames, sizes,
SHA-256 sums, dimensions — so that two people can confirm they are holding the same
data without either of them publishing it.

Aggregated results are a different matter and are committed: a correlation per genus,
a distance per specimen, a figure. None of them can be inverted back into an abundance
profile.

### Specimen labels of the Michigan cohort

The specimen labels of the Michigan cohort
([`NEXT_STAGE_MICHIGAN_COHORT.md`](NEXT_STAGE_MICHIGAN_COHORT.md)) are participant-level
data, not neutral identifiers. According to notes the study's investigators sent with the
data (`NOTAS Archivos.docx`, SHA-256
`f370c5666de79f6463c6476f3216e63fef90a3ccc3caa0bc97d91ec9f88a7694`, held with the project
data), each label encodes the pregnancy outcome and the time of collection, and its final
number is an identifier assigned by the hospital of origin, not a study ID. A label is
therefore a pointer into a hospital's records, joined to a clinical outcome.

- **No real label is written into a committed file or a commit message.** Where a document
  needs an example, it uses an invented one in which no field is a value a real label can
  take (`X0.0.000`), and says that it is invented. Labels with an irregular form are
  described by their pattern, not quoted.
- **The key is not reproduced here.** The notes stay with the project data, identified by the
  hash above.
- **The Michigan OTU table and reads are not deposited in any public place under these
  labels**, and neither is any file derived from them that carries the labels. Every label —
  the OTU table's column names, the identifier of every read record, the specimen column of
  any output — is first replaced by a code with no outcome, time or hospital component, and
  the table linking the new codes to the old labels stays with the project data. The same
  holds for the repository that analyses the external cohorts,
  [`Mexican-PretermBirth-external-cohorts`](https://github.com/martinruhle/Mexican-PretermBirth-external-cohorts).
  Tracked as [`KNOWN_ISSUES.md`](../KNOWN_ISSUES.md) item 13.

## Getting access

The cohort is coordinated at the Instituto Nacional de Perinatología, Mexico City.
Requests for material beyond what is in SRA go through the study team; see the
corresponding section of the analysis compendium, which is the repository cited in the
published article's data availability statement.

---

*Last updated 2026-11-10.*
