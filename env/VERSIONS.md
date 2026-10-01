# Software versions

Two different things need pinning in this project, and they are pinned in two
different ways.

## 1. The pipeline itself — pinned by the workflow commit, plus a patch

MaLiAmPi runs every step inside a container whose tag is written into the workflow
source. We do not choose those tags; the workflow source does. Pinning the commit
therefore pins the whole tool chain.

> ### `3239c625a8` is not a revision
>
> This repository used to quote `3239c625a8` as the workflow revision, because that is
> what the Nextflow log prints. It is **not a git commit**: `git cat-file -t 3239c625a8`
> fails in the clone that ran. It is the script id Nextflow computes for the launched
> `main.nf` — re-launching that same patched file with `--help` on 2026-09-24 printed the
> same string. Passing it to `nextflow run -r` would fail.
>
> The real pin is the commit **plus** the local patch
> ([`workflow/patches/main.nf.pplacer.patch`](../workflow/patches/main.nf.pplacer.patch)).
> Usefully, the script id is a checksum of the patched file, so it is also evidence that
> the file which ran is the one the patch reconstructs.

| | Value | Verified from |
|---|---|---|
| Workflow | `github.com/jgolob/maliampi`, **locally modified** (`main.nf`) | `git remote -v` in the clone, 2026-09-24 |
| **Commit** | **`333d83ba988157fcae07200dcdc861f6b3306938`**, tag `v3.5.0` | `git log -1` in the clone |
| Script id reported by Nextflow | `3239c625a8` (not a commit; see box) | [`logs/nextflow_runtime_header.txt`](../logs/nextflow_runtime_header.txt) |
| Nextflow | 25.04.8 build 5956 | same |
| Groovy / JVM | Groovy 4.0.26 on OpenJDK 17.0.16 | same |
| Kernel | Linux 6.6.87.2-microsoft-standard-WSL2 | same |
| Container runtime | Docker, `runOptions = "-u 1000:1000"` | [`nextflow.config`](nextflow.config) |
| RAxML (inside its container) | 8.2.4, invoked as `raxmlHPC-PTHREADS-AVX2 -m GTRGAMMA -p 12345 -T 1` | [`metadata/refpkg_RAxML_info.txt`](../metadata/refpkg_RAxML_info.txt) |

### Container tags

Read off the pinned commit on 2026-09-24 with:

```bash
grep -rhoE "container__[a-z0-9_]+ *= *['\"][^'\"]+['\"]" main.nf modules/*.nf | sort -u
```

Match both quote styles: `trim-galore` and `fastqc` are declared with single quotes, and
a double-quote-only pattern silently misses them.

| Step | Image |
|---|---|
| barcodecop | `golob/barcodecop:0.5__bc_1` |
| DADA2 | `quay.io/biocontainers/bioconductor-dada2:1.26.0--r42hc247a5b_0` |
| DADA2 → pplacer glue | `golob/dada2-pplacer:0.8.0__bcw_0.3.1A` |
| seqtab combination | `golob/dada2-fast-combineseqtab:0.5.0__1.12.0__BCW_0.3.1` |
| EPA-NG (not used; pplacer replaced it) | `quay.io/biocontainers/epa-ng:0.3.8--h9a82719_1` |
| fastatools | `golob/fastatools:0.8.0A` and `golob/fastatools:0.8.5A` |
| gappa | `golob/gappa:0.3` |
| goodsfilter | `golob/goodsfilter:0.1.6` |
| Infernal (`cmalign`) | `quay.io/biocontainers/infernal:1.1.4--h779adbc_0` |
| pplacer | `golob/pplacer:1.1alpha19rc_BCW_0.3.1A` |
| RAxML | `quay.io/biocontainers/raxml:8.2.4--h779adbc_4` |
| seqinfo/taxonomy sync | `golob/seqinfo_taxonomy_sync:0.3.0` |
| swarm | `quay.io/biocontainers/swarm:3.1.2--h9f5acd7_0` |
| taxtastic | `golob/taxtastic:0.9.5D` |
| TrimGalore | `quay.io/biocontainers/trim-galore:0.6.6--0` |
| FastQC | `biocontainers/fastqc:v0.11.9_cv8` |
| vsearch | `quay.io/biocontainers/vsearch:2.22.1--hf1761c0_0` |

Only `golob/taxtastic:0.9.5D` and the Infernal image appear in the surviving logs, which
is expected: the final session resumed from cache and ran ten processes. The rest come
from the source at the pinned commit, which is what determines them.

## 2. The downstream tooling — not yet pinned

The steps that come *after* MaLiAmPi are not containerised by the workflow and are the
subject of a separate objective. They are not installed from a recorded environment
today, which means the next stage is currently not reproducible on another machine.

| Tool | Purpose | Version |
|---|---|---|
| VALENCIA | community state type assignment from species tables | **pending** |
| MaLiAmPi phylotype binning | phylotypes at 0.1 / 0.5 / 1.0 | **pending** |
| Python (for the VALENCIA conversion scripts) | | **pending** |
| R + packages for the concordance report | R 4.4.2; tidyverse 2.0.0, vegan 2.7.2, patchwork 1.3.2, ggrepel 0.9.6; for the reproducible report also readxl 1.4.5, here 1.0.2, digest 0.6.37, rmarkdown 2.30, knitr 1.51 | ✅ captured — [`results/concordance/as_run_2026-09-21/run_curation_on.log`](../results/concordance/as_run_2026-09-21/run_curation_on.log), and the full `sessionInfo()` at the end of [`analysis/concordance_qiime2_maliampi.html`](../analysis/concordance_qiime2_maliampi.html). Still needs pinning in the environment file, not just recording |

The product that closes this gap is a conda environment file with exact pins, not
ranges: [`environment-16s.PENDING.yml`](environment-16s.PENDING.yml). It is deliberately
named `PENDING` so that nobody creates an environment from it while the versions are
still placeholders.

**Rule for filling it in:** every version in that file must be read off an installed
tool or a lockfile. None may be guessed, and none may be copied from documentation
without checking the machine that actually ran the analysis.

---

*Last updated 2026-09-24.*
