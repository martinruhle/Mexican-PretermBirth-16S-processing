# The MaLiAmPi run of the Mexican preterm birth cohort

This is the record of the run that produced the sequence variants, the reference
package, the phylogenetic placements and the taxonomic tables now used downstream.
It is written so that somebody who has never seen the project can tell what was run,
against what, with which software, and what came out — and can check each claim
against a file in this repository.

The reference package the run built is documented separately, in
[`REFPKG_PROVENANCE.md`](REFPKG_PROVENANCE.md).

---

## 1. In one paragraph

111 vaginal 16S amplicon libraries (V3–V4, paired-end, Illumina MiSeq) from the Mexican
preterm birth cohort were processed with **MaLiAmPi**, in the `maliampi_pplacer` variant
at workflow revision `3239c625a8`, under **Nextflow 25.04.8** on a laptop running Ubuntu
under WSL2, with Docker containers and 6 CPUs / 11.5 GB of RAM. The pipeline denoised
the reads with DADA2, built a 16S reference package from the ARF reference sequence
repository, placed every sequence variant on that reference phylogeny with pplacer, and
classified the placements into taxonomic tables. The run was carried out in many resumed
sessions and finished on **2026-02-18 12:00:03**, with **970.1 accumulated CPU hours**.
No specimen failed. Phylotype binning — the step that would let these data be pooled
with the DREAM Challenge cohorts — **was not run**.

Most of what makes this run worth documenting is not the happy path but the four memory
and compatibility problems that had to be solved to fit it on a laptop:
[`TROUBLESHOOTING.md`](TROUBLESHOOTING.md).

---

## 2. Input

| | |
|---|---|
| Specimens in the manifest | 111 |
| Reads | paired-end FASTQ, one R1/R2 pair per specimen (222 files) |
| Manifest columns | `specimen,R1,R2,batch` — see [`workflow/manifest_template.csv`](../workflow/manifest_template.csv) |
| `batch` values | 12 groups: `lote_1`–`lote_3` with 10 specimens each, `lote_4`–`lote_12` with 9 each |
| Reference repository | ARF release `arf_20200420`, from Zenodo (<https://zenodo.org/records/6876634>), unpacked at `~/arf_20200420/`. Inputs used: `dedup/1200bp/named/filtered/seqs.fasta`, the matching `seq_info.csv`, and the `taxdmp.zip` shipped with it |

> ### ⚠️ The `batch` column is not a sequencing batch
>
> Anyone reading a column called `batch` will assume library preparation batches and may
> reach for it as a technical covariate. **It is not one.** All 111 specimens come from
> one sequencing effort. The column is an engineering device: MaLiAmPi dereplicates all
> specimens of a batch together, and dereplicating 111 at once exhausted the available
> RAM, so they were split into 12 artificial groups of 9–10
> ([`TROUBLESHOOTING.md` §1](TROUBLESHOOTING.md)).
>
> This has one real methodological cost, stated here rather than buried: **DADA2 learns
> its error model per batch**, so the run carries twelve error models built from 9–10
> specimens each, instead of one built from 111. That is a less robust error model, and
> it is a consequence of the memory workaround, not a design choice.
>
> If any downstream analysis has treated `batch` as a batch effect to correct for, that
> should be revisited.

The FASTQ files are not in this repository and never will be; see
[`DATA_ACCESS.md`](DATA_ACCESS.md). The raw reads for this cohort are deposited in the
NCBI Sequence Read Archive under BioProject **PRJNA1440471**.

> **Resolved — 111 vs 110.** The MaLiAmPi tables carry 111 specimen columns, while the
> genus-level analysis matrix used in
> [`Mexican-PretermBirth-analysis`](https://github.com/martinruhle/Mexican-PretermBirth-analysis)
> has 110 rows. `failed_specimens.csv` is empty, so nothing failed inside MaLiAmPi. The
> missing specimen is **Au297**. It has 328 counts in QIIME2, below the 1,000-count filter
> in `convert_to_relative_abundance.R`, so it is dropped on the QIIME2 side. The canonical
> specimen map records this ([`KNOWN_ISSUES.md`](../KNOWN_ISSUES.md) item 6).

---

## 3. What was run

> ### ⚠️ The command below is from a session that failed, not from the final one
>
> The only Nextflow log kept in the project is the one from `Nov-06`, session
> `jovial_mercator`, and that session **failed** at `make_refpkg_wf:TaxtableForSI`. The
> command recorded in it is the one shown here.
>
> The final successful run additionally passed **`--cmalign_mxsize 4096`** and a reduced
> CPU count for `AlignSV`, the settings that got `cmalign` to fit in memory
> ([`TROUBLESHOOTING.md` §4](TROUBLESHOOTING.md)). **That exact command line is not in
> any file kept in the project.** Recovering it needs the WSL machine:
>
> ```bash
> cd ~/datos_microbiota_vaginal
> cat .nextflow/history          # one line per run, with the full command
> ls -lt .nextflow.log*          # rotated logs
> ```
>
> Until that is done, treat the command below as the *shape* of the invocation, not as
> the exact reproduction recipe. Tracked in [`../KNOWN_ISSUES.md`](../KNOWN_ISSUES.md).

The command as logged, verbatim, is in
[`logs/maliampi_launch_command.txt`](../logs/maliampi_launch_command.txt). A
re-runnable version, with the paths lifted into environment variables, is
[`workflow/run_maliampi.sh`](../workflow/run_maliampi.sh).

```
nextflow run jgolob/maliampi_pplacer -profile standard -resume
  -w $WORK_DIR
  --manifest $MANIFEST
  --output $OUTPUT_DIR
  --repo_fasta $ARF/dedup/1200bp/named/filtered/seqs.fasta
  --repo_si    $ARF/dedup/1200bp/named/filtered/seq_info.csv
  --taxdmp     $ARF/taxdmp.zip
```

Sub-workflows executed: `preprocess_wf` (barcodecop, FastQC, TrimGalore) →
`dada2_wf` (filter and trim, dereplicate, per-batch error model, denoise, merge,
combine seqtabs, remove bimeras) → `make_refpkg_wf` (build the reference package) →
`pplacer_place_classify_wf` (align, place, reduplicate, ADCL, EDPL, PCA, alpha
diversity, KR distance, classify, tables).

## 4. Software and hardware

| | |
|---|---|
| Workflow | `maliampi_pplacer`, revision **`3239c625a8`**, **locally modified** — see the box below |
| Engine | Nextflow **25.04.8** build 5956 |
| Runtime | Groovy 4.0.26 on OpenJDK 17.0.16 |
| OS | Linux 6.6.87.2-microsoft-standard-WSL2 (Ubuntu under WSL2 on a Windows host) |
| Executor | `local`, Docker enabled (`-u 1000:1000`) |
| Resources | 6 CPUs, 11.7 GB RAM, 8 GB swap (see [`env/wslconfig.txt`](../env/wslconfig.txt)) |
| Process profile | `standard` — per-label CPU and memory caps in [`env/nextflow.config`](../env/nextflow.config) |
| Tool versions inside containers | pinned by the workflow revision, not by us. The one container tag that appears in our own log is `golob/taxtastic:0.9.5D`. See [`env/VERSIONS.md`](../env/VERSIONS.md) |

Verbatim source: [`logs/nextflow_runtime_header.txt`](../logs/nextflow_runtime_header.txt).

> ### ⚠️ The pipeline was not run stock
>
> Two departures from an off-the-shelf `nextflow run`, both of which have to be
> reproduced or the run cannot be:
>
> 1. **Placement uses pplacer, not EPA-NG.** The `maliampi_pplacer` variant was used
>    instead of the default path, because of a known `gappa` problem inside the EPA-NG
>    module; using `pplacer_place_classify.nf` is the author's own recommendation.
> 2. **`main.nf` was edited locally.** In `//Modules`,
>    `include { epang_place_classify_wf }` was changed to
>    `include { pplacer_place_classify_wf }`; in *STEP 3. Place and Classify*, the call
>    `epang_place_classify_wf(sv_fasta, refpkg_tgz, sv_long)` was replaced by
>    `pplacer_place_classify_wf(sv_fasta, refpkg_tgz, sv_weights, sv_map)`.
>
> **The patch itself is not in this repository yet.** It has to be generated on the WSL
> machine, where the modified file lives:
>
> ```bash
> cd ~/.nextflow/assets/jgolob/maliampi_pplacer
> git diff main.nf > main.nf.patch     # then commit it to workflow/patches/
> ```
>
> Describing the edit in prose, as above, is a stopgap. Until the patch file is here,
> `workflow/run_maliampi.sh` will not reproduce this run on a clean machine. Tracked in
> [`../KNOWN_ISSUES.md`](../KNOWN_ISSUES.md).

## 5. Execution history

The run was not a single invocation. It was launched repeatedly with `-resume` over
several months on a laptop, so in any one session most processes report as cached.

| | |
|---|---|
| A failed intermediate session | `make_refpkg_wf:TaxtableForSI` exited 1 (`succeededCount=5; failedCount=1; cachedCount=1113`). The session was relaunched and the process later completed. |
| Final session | run name `serene_gautier`, **completed 18-Feb-2026 12:00:03**, duration 5 m 48 s, 10 succeeded / 1,133 cached |
| Accumulated compute | **970.1 CPU hours** |

Full process table and completion trailer:
[`logs/maliampi_run_summary_2026-02-18.txt`](../logs/maliampi_run_summary_2026-02-18.txt).

## 6. Output

Directory layout under the `--output` directory. Every file, with its size and
SHA-256, is listed in
[`metadata/maliampi_outputs_manifest.csv`](../metadata/maliampi_outputs_manifest.csv)
(41 files, about 1.3 GB — none of them versioned here).

| Path | What it is | Size |
|---|---|---|
| `sv/dada2.sv.fasta` | **21,382** sequence variants | 9.1 MB |
| `sv/dada2.specimen.sv.long.csv` | per-specimen SV counts, long form | 5.4 MB |
| `sv/errM/lote_*/` | DADA2 error model per batch | small |
| `sv/failed_specimens.csv` | empty — no specimen failed | 24 B |
| `refpkg/refpkg.tar.gz` | the reference package built by the run | 6.1 MB |
| `placement/dedup.jplace` | placements of the deduplicated SVs on the reference tree | 57 MB |
| `placement/redup.jplace.gz` | placements expanded back to all reads | 13 MB |
| `placement/adcl.csv.gz`, `placement/edpl.csv.gz` | per-placement uncertainty measures | small |
| `placement/alpha_diversity.csv.gz`, `placement/kr_distance.csv.gz` | phylogenetic alpha diversity; Kantorovich–Rubinstein distances between specimens | small |
| `placement/pca/epca.*`, `placement/pca/lpca.*` | edge PCA and length PCA projections | 11 MB |
| `classify/classify.mcc.db` | full classification database | 1.1 GB |
| `classify/sv_taxonomy.csv` | taxonomy assigned to each SV | 46 MB |
| `classify/tables/tallies_wide.<rank>.csv` | **taxon × specimen matrices of pplacer weights** — see the warning below | ≤ 251 KB |
| `classify/tables/by_specimen.<rank>.csv`, `classify/tables/by_taxon.<rank>.csv` | the same tallies in long form, with placement frequency | ≤ 665 KB |

Table dimensions, counted directly from the files:

| Rank | Taxa | Specimens |
|---|---|---|
| genus | **547** | 111 |
| species | **913** | 111 |

(`tallies_wide.*` carries three leading columns — `tax_name`, `tax_id`, `rank` — before
the 111 specimen columns.)

> ### ⚠️ `tallies_wide.*` does not contain read counts
>
> The values are **weights redistributed by pplacer** across the taxa a sequence variant
> could belong to, under the `hybrid2` classifier. Two consequences:
>
> - Per-specimen totals in `tallies_wide.*` can **exceed** the DADA2 read counts for that
>   specimen. This is expected behaviour, not corrupted data.
> - A histogram of "reads per specimen" built on `tallies_wide.*` is **not** a histogram
>   of reads. For read counts, use `sv/dada2.specimen.sv.long.csv`.
>
> `tallies_wide.species.csv` also carries an unnamed phantom column, an artefact of how
> the CSV is written. It affects parsing, not integrity.

Counts from the denoising stage, read directly from the outputs:

| | |
|---|---|
| Unique sequence variants after chimera removal | **21,382** |
| Specimen × SV observations with a non-zero count | 177,503 |
| Total reads after chimera removal | 28,277,142 |

> **These two numbers are easy to confuse, and have been confused before.** 21,382 is the
> number of *distinct* sequence variants. 177,503 is the number of *specimen–variant
> pairs* with a non-zero count in the long-format table — roughly eight times larger, and
> not an ASV count. Where this document says "sequence variants", it means 21,382.

For comparison, the QIIME2/DADA2 table used in the concordance analysis carries **77**
genera. That gain in resolution is the reason for switching pipelines;
whether the two pipelines describe the *same* microbiome is the question answered in
[`CONCORDANCE_QIIME2_MALIAMPI.md`](CONCORDANCE_QIIME2_MALIAMPI.md).

## 7. What this run did **not** do

- **Phylotype binning.** MaLiAmPi can group placements into phylotypes at chosen
  phylogenetic distances (0.1, 0.5 and 1.0 are the thresholds planned here). That step
  was not executed. Phylotypes, rather than taxonomic names, are the representation
  that lets technically dissimilar cohorts be pooled, so this sits on the critical path
  to any external validation.
- **Placement against the DREAM Challenge reference package.** See
  [`NEXT_STAGE_DREAM_REFPKG.md`](NEXT_STAGE_DREAM_REFPKG.md).
- **Any downstream modelling.** That lives in the analysis compendium, not here.

## 8. How to re-run and how to check

Reproducing the run end to end needs the FASTQ files, the ARF repository and roughly a
thousand CPU hours. What can be checked cheaply, from this repository alone:

```bash
# 1. Is the reference package the one this record describes?
Rscript scripts/describe_refpkg.R /path/to/refpkg.tar.gz
# the sha256 it prints must be
# 2a3ce022576744c0c0bd858f005db52ab2c27e6ec249a55c56ef3e9c87622b2e
```

```bash
# 2. Are the outputs the ones this record describes?
MALIAMPI_OUT=/path/to/salida_analisis bash scripts/make_output_manifest.sh
git diff --stat metadata/maliampi_outputs_manifest.csv   # must come back empty
```

To launch the pipeline again from reads, edit the paths at the top of
[`workflow/run_maliampi.sh`](../workflow/run_maliampi.sh) and run it. Keep the
`-resume` flag and the same work directory: on this hardware a cold run is measured in
weeks, not hours.

---

| | |
|---|---|
| Written | 2026-08-30 |
| Reviewed by | *pending* |
