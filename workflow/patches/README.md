# Patches

## `main.nf.patch` — MISSING

The documented run used a **locally modified** `main.nf`: EPA-NG placement was replaced
by pplacer, because of a known `gappa` problem inside the EPA-NG module. Without this
patch, pulling workflow revision `3239c625a8` gives you a different pipeline than the one
that produced the results described in `docs/`.

The change, in prose (a stopgap — the patch file is what belongs here):

- in `//Modules`: `include { epang_place_classify_wf }` becomes
  `include { pplacer_place_classify_wf }`
- in *STEP 3. Place and Classify*:
  `epang_place_classify_wf(sv_fasta, refpkg_tgz, sv_long)` becomes
  `pplacer_place_classify_wf(sv_fasta, refpkg_tgz, sv_weights, sv_map)`

To produce it, on the machine that holds the modified copy:

```bash
cd ~/.nextflow/assets/jgolob/maliampi_pplacer
git diff main.nf > main.nf.patch
```

Then commit `main.nf.patch` here and remove this notice.

**Do not reconstruct the patch by hand from the prose above.** A patch that has not been
diffed against the real file is a guess, and a guess in a reproduction recipe is worse
than an acknowledged gap. Tracked in `../../KNOWN_ISSUES.md`, item 2.
