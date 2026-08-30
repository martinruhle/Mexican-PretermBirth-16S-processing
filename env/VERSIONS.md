# Software versions

Two different things need pinning in this project, and they are pinned in two
different ways.

## 1. The pipeline itself — pinned by the workflow revision

MaLiAmPi runs every step inside a container whose tag is written into the workflow
source. We do not choose those tags; the workflow revision does. Pinning the revision
therefore pins the whole tool chain.

| | Value | Verified from |
|---|---|---|
| Workflow | `jgolob/maliampi_pplacer` | [`logs/nextflow_runtime_header.txt`](../logs/nextflow_runtime_header.txt) |
| **Revision** | **`3239c625a8`** | same |
| Nextflow | 25.04.8 build 5956 | same |
| Groovy / JVM | Groovy 4.0.26 on OpenJDK 17.0.16 | same |
| Kernel | Linux 6.6.87.2-microsoft-standard-WSL2 | same |
| Container runtime | Docker, `runOptions = "-u 1000:1000"` | [`nextflow.config`](nextflow.config) |
| One container tag visible in our log | `golob/taxtastic:0.9.5D` | Nextflow debug log |
| RAxML (inside its container) | 8.2.4, invoked as `raxmlHPC-PTHREADS-AVX2 -m GTRGAMMA -p 12345 -T 1` | [`metadata/refpkg_RAxML_info.txt`](../metadata/refpkg_RAxML_info.txt) |

**Not yet captured:** the container tags for DADA2, pplacer, barcodecop, TrimGalore and
FastQC. They are visible in the workflow source at revision `3239c625a8` and in a
Nextflow execution trace, and belong in this table.

To capture them:

```bash
# from the workflow source
grep -rn "container" ~/.nextflow/assets/jgolob/maliampi_pplacer/ | sort -u
```

```bash
# or from a run, by asking Nextflow for a trace next time
nextflow run jgolob/maliampi_pplacer -resume -with-trace -with-report ...
```

## 2. The downstream tooling — not yet pinned

The steps that come *after* MaLiAmPi are not containerised by the workflow and are the
subject of a separate objective. They are not installed from a recorded environment
today, which means the next stage is currently not reproducible on another machine.

| Tool | Purpose | Version |
|---|---|---|
| VALENCIA | community state type assignment from species tables | **pending** |
| MaLiAmPi phylotype binning | phylotypes at 0.1 / 0.5 / 1.0 | **pending** |
| Python (for the VALENCIA conversion scripts) | | **pending** |
| R + packages for the concordance report | tidyverse, vegan, patchwork, ggrepel, scales | **pending** — the as-run script prints them but the values were not kept |

The product that closes this gap is a conda environment file with exact pins, not
ranges: [`environment-16s.PENDING.yml`](environment-16s.PENDING.yml). It is deliberately
named `PENDING` so that nobody creates an environment from it while the versions are
still placeholders.

**Rule for filling it in:** every version in that file must be read off an installed
tool or a lockfile. None may be guessed, and none may be copied from documentation
without checking the machine that actually ran the analysis.

---

*Last updated 2026-08-30.*
