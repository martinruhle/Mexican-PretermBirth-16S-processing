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

## 2. The downstream tooling — partly pinned

The steps that come *after* MaLiAmPi are not containerised by the workflow. VALENCIA and
the Python that runs it are now pinned and install from a recorded environment (below).
The phylotype binning and the R side are not yet installed from one.

| Tool | Purpose | Version |
|---|---|---|
| VALENCIA | community state type assignment from species tables | ✅ **commit `8559d454387479f7155333693d854961463c3b15`** of `github.com/ravel-lab/VALENCIA` — see [VALENCIA](#valencia--pinned-by-its-commit-in-a-pip-virtual-environment) |
| MaLiAmPi phylotype binning | phylotypes at 0.1 / 0.5 / 1.0 | **pending** |
| Python (for VALENCIA and the conversion of our species table to its input) | | ✅ Python 3.10.12 (Ubuntu 22.04 package `python3.10` `3.10.12-1~22.04.18`), in a pip virtual environment; pandas 2.3.3, numpy 2.2.6, matplotlib 3.10.9 and their dependencies pinned in [`valencia-requirements.txt`](valencia-requirements.txt) |
| R + packages for the concordance report | R 4.4.2; tidyverse 2.0.0, vegan 2.7.2, patchwork 1.3.2, ggrepel 0.9.6; for the reproducible report also readxl 1.4.5, here 1.0.2, digest 0.6.37, rmarkdown 2.30, knitr 1.51 | ✅ captured — [`results/concordance/as_run_2026-09-21/run_curation_on.log`](../results/concordance/as_run_2026-09-21/run_curation_on.log), and the full `sessionInfo()` at the end of [`analysis/concordance_qiime2_maliampi.html`](../analysis/concordance_qiime2_maliampi.html). Still needs pinning in the environment file, not just recording |

The product that closes this gap is a conda environment file with exact pins, not
ranges: [`environment-16s.PENDING.yml`](environment-16s.PENDING.yml). It is deliberately
named `PENDING` so that nobody creates an environment from it while the versions are
still placeholders.

**Rule for filling it in:** every version in that file must be read off an installed
tool or a lockfile. None may be guessed, and none may be copied from documentation
without checking the machine that actually ran the analysis.

VALENCIA is the exception to the conda file: it never ran from conda, so its Python side
is pinned as a pip requirements file instead (next section), and the conda file only
points to it.

### VALENCIA — pinned by its commit, in a pip virtual environment

VALENCIA is not packaged on conda or PyPI; it is a script (`Valencia.py`) plus a
reference centroids file in its own repository, so the only way to pin it is the commit.

| | Value | Verified from |
|---|---|---|
| Repository | `https://github.com/ravel-lab/VALENCIA`, branch `master` | `git remote -v` in the clone that ran (`~/VALENCIA`, WSL), 2026-10-26 |
| **Commit** | **`8559d454387479f7155333693d854961463c3b15`** (2023-04-18, "Merge pull request #10 from ravel-lab/add-license-1"); no local changes; the upstream `HEAD` on 2026-10-26 | `git log -1`, `git status` in that clone |
| `Valencia.py` | sha256 `8714f524d2ee4c803c5cff5ef99719a776d8e5301b6ffd58f4cc06fba25fa478` | same clone, and a fresh clone at the commit |
| `CST_centroids_012920.csv` | sha256 `9d18456724e439a1e828ff2dd34dd12e51cc08729ae025aaafabe05390093e96` | same |
| Python | 3.10.12, the system `python3` of Ubuntu 22.04 (package `python3.10` `3.10.12-1~22.04.18` on 2026-10-28), not a conda Python | `pyvenv.cfg` of the venv that ran (`~/valencia_env`), `dpkg -l` |
| Python packages | [`valencia-requirements.txt`](valencia-requirements.txt): exact pins read with `pip freeze` from `~/valencia_env` on 2026-10-28 | that venv was created on 2026-05-25 with an unpinned `pip install pandas numpy matplotlib` (shell history); the file records what that resolved to |

`matplotlib` is only needed for VALENCIA's optional `-p` plot. The venv that ran also
holds scipy 1.15.3, installed later for a downstream analysis script outside this
repository; it is left out of the requirements because neither `Valencia.py` nor the
conversion script imports it.

**Why pandas must stay pinned.** At this commit `Valencia.py` reads the centroid
medians by position with `Series[int]` (lines 54–55). pandas 2.3.3 still accepts that,
with a `FutureWarning` ("Series.__getitem__ treating keys as positions is deprecated");
the deprecation says integer keys will be read as labels in a future version. An
unpinned install could therefore stop reproducing the assignments, or fail.

#### Installing it

On Ubuntu 22.04 (or WSL `Ubuntu-22.04`), with the system Python:

```bash
sudo apt install python3-venv                       # once, if `python3 -m venv` is missing
git clone https://github.com/ravel-lab/VALENCIA.git
git -C VALENCIA checkout 8559d454387479f7155333693d854961463c3b15
python3 -m venv valencia_env
valencia_env/bin/pip install -r env/valencia-requirements.txt   # path into this repository
valencia_env/bin/python VALENCIA/Valencia.py \
  -ref VALENCIA/CST_centroids_012920.csv -i <input>.csv -o <output_prefix> [-p <plot_prefix>]
```

The reference file is `CST_centroids_012920.csv`; the VALENCIA README calls it
`CST_profiles_012920.csv`, a name that does not exist in the repository. `-o` and `-p`
are prefixes: the output is written to `<output_prefix>.csv`.

#### Checked from scratch

[`scripts/check_valencia_install.sh`](../scripts/check_valencia_install.sh) does exactly
the steps above in a new temporary directory (fresh clone, fresh venv, the pip 22.0.2
that Ubuntu's venv ships) and compares the result with the files of 2026-05-25, without
touching the clone or the venv that produced them. Its output, run on 2026-10-28, is in
[`results/valencia_install_check/check_valencia_install.log`](../results/valencia_install_check/check_valencia_install.log):

- `pip freeze` of the new venv equals the 14 pins of the requirements file;
- `Valencia.py` and the centroids of the new clone have the same sha256 as those of the
  clone that ran;
- on the input of 2026-05-25 (sha256 `7388b531…`), the new install writes an output with
  sha256 `0805b305c0bb8a85bb371794c9a23213872b65d14ebc196f4b427f23c26fac42`,
  byte-identical to the output of 2026-05-25;
- regenerating that input with an unmodified copy of the conversion script of
  2026-05-25 gives the same input and the same output, byte for byte.

Both files hold per-specimen abundances and are not in this repository; only their
hashes are.

---

*Last updated 2026-10-28.*
