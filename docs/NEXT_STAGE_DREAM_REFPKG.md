# 🚧 Next stage — placement against the DREAM Challenge reference package

**Status: not started.** Nothing in this document has been executed. It is written
now so that the goal, the preconditions and the acceptance criteria are on record
before any work begins, and so that a reader arriving from
[`REFPKG_PROVENANCE.md`](REFPKG_PROVENANCE.md) can see where that conclusion leads.

---

## 1. Why this stage exists

Our MaLiAmPi run built [its own reference package](REFPKG_PROVENANCE.md). MaLiAmPi
assigns taxonomy by *placing* each sequence variant on a reference phylogeny, and a
phylotype is a bin of placements on that phylogeny at a chosen phylogenetic distance.
Two consequences:

- **Taxonomic names transfer between reference packages.** *Lactobacillus crispatus*
  means the same thing whichever tree produced the label. Genus- and species-level
  comparisons across pipelines are therefore meaningful, and one has already been done
  (see [`CONCORDANCE_QIIME2_MALIAMPI.md`](CONCORDANCE_QIIME2_MALIAMPI.md)).
- **Phylotype identifiers do not transfer.** They are defined by the tree they were cut
  from. Phylotype `X` in our output and phylotype `X` in the DREAM Challenge tables are
  not the same object, and no lookup table can make them so.

The planned external validation is bidirectional — train on the Mexican cohort, apply
to the DREAM hispanic subgroup (about 50 participants), and the reverse. That requires
both cohorts to be described in **one** phylotype space. Hence: re-place our sequence
variants against the DREAM reference package.

## 2. What this stage does *not* require

- **No re-sequencing and no re-denoising.** The sequence variants already exist
  (`sv/dada2.sv.fasta`, 21,382 SVs, SHA-256 in
  [`metadata/maliampi_outputs_manifest.csv`](../metadata/maliampi_outputs_manifest.csv)).
  Only the placement and classification sub-workflow needs to run again.
- **No change to the published manuscript.** The published analysis is genus-level and
  stands on the QIIME2 tables. This stage feeds the *next* manuscript.

## 3. Preconditions, in order

Each is a separate piece of work with its own product. None has been done.

| # | Task | Product that proves it is done |
|---|---|---|
| 1 | Establish where the local ARF copy at `~/arf_20200420/` came from — a public ARF release, a colleague, or a rebuild. This decides how far our reference package really is from the DREAM one. | A section added to [`REFPKG_PROVENANCE.md`](REFPKG_PROVENANCE.md) naming the source, with whatever evidence exists (download URL, README, checksum, correspondence) or an explicit statement that it could not be established. |
| 2 | Obtain the DREAM Challenge reference package. Candidate sources, none yet checked: the Challenge Synapse project (`syn26133770`), the [`maliampi`](https://github.com/jgolob/maliampi) repository and its releases, the supplementary material of Golob et al. 2024 (*Cell Rep Med* 5(1):101359), or a request to the authors. | The archive on disk, plus a row in this document giving origin, retrieval date, version or release tag, and SHA-256. If it turns out not to be distributable, that answer is recorded here instead — a documented dead end closes the objective just as well as a download. |
| 3 | Compare the two reference packages. | `Rscript scripts/describe_refpkg.R` run on both, outputs saved side by side under `metadata/`, and a short verdict: how many reference sequences each has, how much of the taxonomy they share, and whether re-placement is worth the compute. |
| 4 | Re-run placement and classification with the DREAM reference package, reusing the existing sequence variants. Confirm the exact parameter name for supplying a pre-built reference package against the workflow source at revision `3239c625a8` before writing the command — our own run never used it. | A second output directory, its own manifest under `metadata/`, and a run record written the same way as [`RUN_MALIAMPI.md`](RUN_MALIAMPI.md). |
| 5 | Bin the placements into phylotypes at 0.1, 0.5 and 1.0. | Phylotype tables, their dimensions recorded, and the thresholds documented. |
| 6 | Check that our phylotype identifiers and the DREAM phylotype identifiers actually coincide. | An overlap report: how many phylotypes are shared, what fraction of each cohort's relative abundance falls in the shared set. This is the real gate — steps 4 and 5 can succeed mechanically and still leave the two cohorts in different spaces. |

## 4. Acceptance criteria for the stage as a whole

A colleague should be able to confirm, without asking anyone:

1. This document names the origin, date, version and SHA-256 of the DREAM reference
   package — or states, with evidence, that it could not be obtained.
2. `metadata/` holds a description of both reference packages, produced by the same
   script.
3. There is a run record for the re-placement, with the same structure as
   [`RUN_MALIAMPI.md`](RUN_MALIAMPI.md), including its own output manifest.
4. There is an overlap report between our phylotypes and the DREAM phylotypes, with an
   explicit verdict on whether the two cohorts can be pooled.
5. The status banner at the top of this file, and the corresponding line in
   [`../README.md`](../README.md), have been updated.

## 5. Known risks

- **The reference package may not be publicly distributed.** The Challenge released
  phylotype *tables*; whether the reference package itself is available has not been
  checked. If it is not, the fallback is to compare in a space that does transfer —
  species-level tables and VALENCIA community state types — and to say plainly that
  phylotype-level pooling was not possible.
- **The reference packages may differ enough that re-placement changes the taxonomy
  too**, not only the phylotypes. If so, the genus-level concordance already
  established for QIIME2 versus MaLiAmPi has to be repeated for the new placement
  before any biological claim is carried over.
- **Compute.** Placement is the expensive half of the pipeline. The original run
  accumulated 970 CPU hours on a laptop; budget accordingly, or move this step to a
  machine that is not a laptop.

---

| | |
|---|---|
| Written | 2026-08-30 |
| Status | not started |
| Reviewed by | *pending* |
