# Patches

## `main.nf.pplacer.patch`

The documented run used a **locally modified** `main.nf`: EPA-NG placement was replaced
by pplacer, because of a known `gappa` problem inside the EPA-NG module
([`docs/TROUBLESHOOTING.md` §6](../../docs/TROUBLESHOOTING.md)). Without this patch you
get a different pipeline than the one that produced the results described in `docs/`.

The patch was generated on 2026-09-24 on the WSL machine that holds the modified copy,
with `git diff main.nf` in `~/.nextflow/assets/jgolob/maliampi_pplacer`. It is 4 lines
added and 3 removed:

- `include { epang_place_classify_wf } from './modules/epang_place_classify'` becomes
  `include { pplacer_place_classify_wf} from './modules/pplacer_place_classify'`
- in *STEP 3. Place and Classify*,
  `epang_place_classify_wf(sv_fasta, refpkg_tgz, sv_long)` becomes
  `pplacer_place_classify_wf(sv_fasta, refpkg_tgz, sv_weights, sv_map)`

## What it applies to

That directory is **not** a separate project: it is a clone of
`https://github.com/jgolob/maliampi.git`, on `master`, at tag **v3.5.0**, commit
`333d83ba988157fcae07200dcdc861f6b3306938`. The local directory name
(`maliampi_pplacer`) is what Nextflow reports in the log; it is not an upstream project.
How the run is pinned — by commit plus this patch, not by the `3239c625a8` string the log
prints — is described in [`env/VERSIONS.md`](../../env/VERSIONS.md).

```bash
git clone https://github.com/jgolob/maliampi.git
cd maliampi
git checkout v3.5.0          # 333d83ba988157fcae07200dcdc861f6b3306938
git apply /path/to/main.nf.pplacer.patch
```

Then point `nextflow run` at that directory, as
[`workflow/run_maliampi.sh`](../run_maliampi.sh) does.

The upstream project has moved on since v3.5.0. Current `master` takes `--placer
epang|pplacer` as an option, which makes this patch unnecessary — but it is a different
pipeline, and it is not what produced these results. See
[`docs/NEXT_STAGE_DREAM_REFPKG.md` §4](../../docs/NEXT_STAGE_DREAM_REFPKG.md).
