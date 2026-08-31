# What broke, and how it was fixed

MaLiAmPi is written for a cluster. This run happened on a laptop with 6 CPUs and 11.5 GB
of RAM available to the pipeline, which is well under what the author's default profile
assumes (`mem_veryhigh = 32 GB`). Every configuration value in
[`env/nextflow.config`](../env/nextflow.config) is scaled down from those defaults.

Getting it to finish took four substantive fixes. They are the part of this record most
likely to be useful to somebody else, so they are written out rather than summarised —
including the one that carries a methodological cost.

Ordered as they were hit.

---

## 1. DADA2 ran out of memory during dereplication

**Symptom.** The process is killed; exit status 137 (the kernel OOM killer), or a
segmentation fault, while dereplicating all 111 specimens at once.

**Cause.** MaLiAmPi dereplicates all specimens belonging to the same `batch` together.
With no `batch` column, all 111 are one batch, and the peak allocation does not fit in
11.7 GB.

**Fix.** An artificial `batch` column was added to the manifest, splitting the specimens
into 12 groups of 9–10 (`lote_1`–`lote_3` with 10, `lote_4`–`lote_12` with 9). The full
memory allowance was reserved for the final merge step (`dada2_seqtab_combine_all`),
which is the one that genuinely needs it.

**Cost — this one is not free.** DADA2 learns its error model **per batch**. Twelve
artificial batches means twelve error models estimated from 9–10 specimens each, rather
than one estimated from 111. The error model is correspondingly less well determined.
Nothing about the within-batch learning is wrong, but the run is not equivalent to a
single-batch run, and any comparison against a study that denoised in one pass should
say so.

**Trap this leaves behind.** The `batch` column now looks like a library preparation
batch to anyone reading the manifest. It is not one — all specimens come from a single
sequencing effort. Treating it as a technical covariate would be modelling an artefact
of the memory workaround. This is flagged again in
[`RUN_MALIAMPI.md` §2](RUN_MALIAMPI.md).

## 2. A mistyped path to the reference repository

**Symptom.** `vsearch` fails in `make_refpkg_wf:RefpkgSearchRepo`.

**Cause.** `arf_2020420` instead of `arf_20200420` — one missing zero.

**Fix.** Correct the path. Recorded because the failure surfaces as a tool error deep
inside a sub-workflow rather than as "file not found", which costs time to diagnose.

## 3. NCBI taxonomy incompatible with `taxtastic`

**Symptom.** `make_refpkg_wf:TaxtableForSI` exits 1, inside
`golob/taxtastic:0.9.5D`:

```
File ".../taxtastic/subcommands/taxtable.py", line 74, in _inner
    return (ref_ranks.index(rank), 0)
ValueError: 'cellular_root' is not in list
```

The same failure appeared in another iteration as `ValueError: 'domain' is not in list`.

**Cause.** NCBI changed the hierarchy of root-level nodes in `taxdmp.zip`. `taxtastic`
0.9.5D expects the previous structure and has no rank named `cellular_root` (or
`domain`) in its ordered list.

**Complication worth knowing about.** Nextflow's cache kept reusing the broken
`taxonomy.db` even after the task's work directory was deleted. **Deleting a task's
`workDir` does not invalidate its cache entry** — the entry is keyed on the inputs, not
on the presence of the outputs.

**Fix.** Supply a compatible taxonomy explicitly, via `--taxdmp`, using the 2020-vintage
`taxdmp.zip` distributed with `arf_20200420`. Adding a parameter changes the input hash,
which is what actually forces the step to re-run. That is the correct way to invalidate
a Nextflow cache entry; `rm -rf` on the work directory is not.

This is also why `--taxdmp` appears in the launch command at all, and it is part of the
evidence that the reference package was built rather than downloaded
([`REFPKG_PROVENANCE.md`](REFPKG_PROVENANCE.md)).

## 4. Persistent out-of-memory in `AlignSV` (`cmalign`)

**Symptom.** Exit code 137 in `pplacer_place_classify_wf:AlignSV`. Four rounds of
adjustment before it held.

**Cause.** `cmalign` allocates its dynamic-programming matrices per thread, so memory
scales with the number of CPUs, not just with the data. More CPUs made it worse.

**Fix.** One CPU for `AlignSV`, and `--cmalign_mxsize 4096`.

**Caveat.** These two values come from the working history of the project and are **not**
present in the Nextflow log that survives. They should be confirmed against
`.nextflow/history` on the WSL machine before anyone relies on them — see
[`../KNOWN_ISSUES.md`](../KNOWN_ISSUES.md).

**Forward-looking consequence.** The DREAM Challenge reference package is larger than
ours. If the sequence variants are re-placed against it
([`NEXT_STAGE_DREAM_REFPKG.md`](NEXT_STAGE_DREAM_REFPKG.md)), this memory problem gets
**worse**, not equal. Budget for a machine with more RAM rather than assuming the same
settings will carry over.

## 5. A Windows Update reboot killed a long run

**Symptom.** The run disappears mid-flight.

**Fix.** Relaunch under `nohup ... &` together with `-resume`, and disable automatic
restarts for the duration. This is why the run appears in the logs as many resumed
sessions with most processes cached, and why the accumulated 970 CPU hours are spread
over months of wall clock.

## 6. A `gappa` problem inside the EPA-NG module

**Fix.** Use the `maliampi_pplacer` variant, which places with pplacer instead of EPA-NG
— the author's own recommendation. This required a local edit to `main.nf`; the exact
change, and the fact that the patch file is not yet in this repository, are documented in
[`RUN_MALIAMPI.md` §4](RUN_MALIAMPI.md).

---

## What this adds up to

The pipeline is runnable on a laptop, but not as shipped. Three of the six items above
are memory pressure, one is a cache subtlety that costs hours if you do not know it, one
is a dependency drift in NCBI's taxonomy, and one is an upstream tool problem. Anyone
attempting this on comparable hardware should read
[`env/nextflow.config`](../env/nextflow.config) and items 1 and 4 before starting.

---

| | |
|---|---|
| Written | 2026-08-30 |
| Reviewed by | *pending* |
