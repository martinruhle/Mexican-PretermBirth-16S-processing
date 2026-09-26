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

This is not an improvised manoeuvre: the Challenge itself added two independent
validation datasets *post hoc*, after the training set had been built, by placing them on
the same reference tree. The mechanism needed here is the same one.

## 2. What this stage does *not* require

- **No re-sequencing and no re-denoising.** The sequence variants already exist
  (`sv/dada2.sv.fasta`, 21,382 SVs, SHA-256 in
  [`metadata/maliampi_outputs_manifest.csv`](../metadata/maliampi_outputs_manifest.csv)).
  Only the placement and classification sub-workflow needs to run again.
- **No change to the published manuscript.** The published analysis is genus-level and
  stands on the QIIME2 tables. This stage feeds the *next* manuscript.

## 3. The direction has to be chosen first

There are two ways to put both cohorts in one feature space. They are **mutually
exclusive**, and the features they produce **cannot be mixed in the same model**.

**Option A — place our sequence variants on the DREAM reference package.**
What the objective as currently written asks for. Our data land directly in the
Challenge's feature space, so the models published with the Challenge apply without
retraining. Requires obtaining their reference package.

**Option B — place the DREAM sequence variants on our reference package.**
Does not depend on obtaining anything from the Challenge, but requires their raw
sequences, part of which are under controlled access, and the results are then **not**
comparable with the Challenge's published models.

> **This is a live inconsistency in the project's own plans, not a hypothetical.** The
> earlier plan for the Michigan dataset was Option B — place Michigan on our reference
> package. The objective as written now is Option A. Changing direction is legitimate;
> running both and mixing the outputs is not. **Decide which is the main line before any
> code is written**, and record the decision here.

The rest of this document assumes Option A.

## 3b. Where the DREAM reference package is not

Checked on 2026-09-24. Recorded because a dead end that is not written down gets searched
again:

| Source | What is actually there |
|---|---|
| `zenodo.org/records/8329650` | The **source code** of MaLiAmPi v3.5.0, "Manuscript and PTB Dream challenge release", published 2023-09-08. Not a reference package. Useful for a different reason: our own run used a clone at tag `v3.5.0`, the same code ([`RUN_MALIAMPI.md` §4](RUN_MALIAMPI.md)) |
| `doi.org/10.5281/zenodo.10015300` — what the paper's key resources table cites as "MaLiAmPi" | Resolves to **jgolob/arf** v0.1, the ARF allele-filtering tool, not MaLiAmPi. The same ARF whose release we used to build our own package ([`REFPKG_PROVENANCE.md`](REFPKG_PROVENANCE.md)). The DOI printed next to "MaLiAmPi" resolves to ARF; the MaLiAmPi release is record `8329650`, above |
| Golob et al. 2024, *Cell Rep Med* 5(1):101359, "Data and code availability" (pp. 17–18) | Lists the nine source studies, the harmonized data (March of Dimes database, study **SDY2187**, via pretermbirthdb.org), the VMAP viewer, and the MaLiAmPi code. **No reference package is deposited anywhere in the list** |
| Synapse `syn26133770` | The Challenge project exists and its wiki is public; registration is closed and the data sit behind registration. Nothing in the public wiki mentions a reference package |

What the Challenge distributed to participants were **phylotype and taxonomy tables**, not
the package they were derived from. That is consistent: participants never needed to place
anything themselves.

Remaining routes, in the order they are worth trying:

1. **Ask.** The paper names the lead contact (Marina Sirota) and MaLiAmPi's author
   (Jonathan Golob), and states that additional information needed to reanalyse the data
   is available from the lead contact on request. A reference package is a small file.
2. **Register** on Synapse / pretermbirthdb and look inside SDY2187 for it.
3. **Rebuild** it with ARF and MaLiAmPi. This produces *a* package from the same tooling,
   not *the* package, so phylotype identifiers still would not transfer. It is the
   fallback of last resort, and it does not satisfy the objective.

## 3c. What the pipeline can and cannot take

Also checked on 2026-09-24, against both the version we ran and current upstream:

- **The version we ran (tag `v3.5.0`) has no parameter for a pre-built reference
  package.** `main.nf` requires `--repo_fasta`, `--repo_si` and `--email`, and always
  calls `make_refpkg_wf`, feeding its output into placement. There is no flag we failed
  to notice; the capability is absent.
- **Current `master` has `--refpkg`**, documented as "Existing reference package", as an
  alternative to `--repo_fasta`/`--repo_si`. It also takes `--placer epang|pplacer`,
  which makes our local patch unnecessary, and adds `--skip_taxonomy`, `--skip_stats`,
  `--skip_phylotypes` and explicit phylotype thresholds.
- **But `master` still starts from the manifest.** It runs its `sv` subworkflow (DADA2)
  and hands *its* output to placement; there is no entry point that takes existing
  sequence variants. It also now requires `--project_id` and `--dataset_id`, and its SV
  artifacts are H5AD files: it is a restructured pipeline, not a drop-in newer version.

The consequence for precondition 4: re-running `master` end to end would **re-denoise**
the reads and could yield a different variant set, which would break comparability with
everything documented here. Placing the existing `sv/dada2.sv.fasta` (21,382 variants,
SHA-256 `d2ef8ad7…`) on the DREAM package with `cmalign` + `pplacer` directly — outside
the workflow, in the same containers the run used — preserves the chain. That is the same
reasoning, for the same reason, as in
[`NEXT_STAGE_OLD_RUN.md` §3](NEXT_STAGE_OLD_RUN.md).

## 4. Preconditions, in order

Each is a separate piece of work with its own product. None has been done.

| # | Task | Product that proves it is done |
|---|---|---|
| 1 | Decide between Option A and Option B (§3) and write the decision down, with the reason. | A dated paragraph in this document naming the chosen direction. Nothing else in this table should start before it. |
| 2 | Obtain the DREAM Challenge reference package. **Partly answered on 2026-09-24 — see §3b. It is not published anywhere we can find; what remains is to ask the authors.** | The archive on disk, plus a row in this document giving origin, retrieval date, version or release tag, and SHA-256. If it turns out not to be distributable, that answer is recorded here instead — a documented dead end closes the objective just as well as a download. |
| 3 | Compare the two reference packages. | `Rscript scripts/describe_refpkg.R` run on both, outputs saved side by side under `metadata/`, and a short verdict: how many reference sequences each has, how much of the taxonomy they share, and whether re-placement is worth the compute. |
| 4 | Re-run placement and classification with the DREAM reference package, reusing the existing sequence variants. **The parameter question is answered — see §3c. The version we ran has no such parameter; current `master` has `--refpkg` but re-runs DADA2.** | A second output directory, its own manifest under `metadata/`, and a run record written the same way as [`RUN_MALIAMPI.md`](RUN_MALIAMPI.md). |
| 5 | Bin the placements into phylotypes at 0.1, 0.5 and 1.0 — using the same phylogenetic distance criterion the Challenge used, not our own. | Phylotype tables, their dimensions recorded, and the thresholds documented. |
| 6 | Assign VALENCIA community state types on the new species tables. | CST assignments, with the VALENCIA commit recorded ([`env/VERSIONS.md`](../env/VERSIONS.md)). CSTs were among the strongest features in the Challenge's winning models, so this is not optional decoration. |
| 7 | Check that our phylotype identifiers and the DREAM phylotype identifiers actually coincide. | An overlap report: how many phylotypes are shared, what fraction of each cohort's relative abundance falls in the shared set. This is the real gate — steps 4 to 6 can succeed mechanically and still leave the two cohorts in different spaces. |

### Questions to settle before estimating any timeline

None of these is resolved, and each can block the stage on its own.

| # | Question | How to answer it |
|---|---|---|
| 1 | ~~Is the DREAM reference package downloadable at all?~~ **Answered 2026-09-24: not from any published source (§3b).** The article publishes the MaLiAmPi code, not the package built with it. | Remaining: ask the authors; failing that, register and look inside SDY2187. |
| 2 | **What data use agreement does Synapse require?** | The Challenge data were aggregated from dbGaP and the March of Dimes database; part of it may need a formal access request with a turnaround of weeks to months. **This is the largest schedule risk in the whole stage, and it is administrative, not technical.** Start it before anything else. |
| 3 | Are the DREAM FASTQ files needed at all, or do their published feature tables suffice? | If the goal is comparing composition, or validating models, the published phylotype tables may be enough — which removes question 2 entirely. The raw sequences are only needed for Option B. Answering this first may dissolve the biggest risk. |
| 4 | Does the DREAM reference package cover V3–V4? | Conceptually yes: the tree is built from full-length 16S alleles, which is exactly why harmonising across different variable regions works. Confirm on inspection anyway. |

## 5. Acceptance criteria for the stage as a whole

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

## 6. Known risks

- **The reference package is not publicly distributed** (§3b, checked 2026-09-24). The
  Challenge released phylotype *tables*. This has moved from a risk to a finding: the
  stage now depends on a request to the authors. If that fails, the fallback is to
  compare in a space that does transfer —
  species-level tables and VALENCIA community state types — and to say plainly that
  phylotype-level pooling was not possible.
- **The reference packages may differ enough that re-placement changes the taxonomy
  too**, not only the phylotypes. If so, the genus-level concordance already
  established for QIIME2 versus MaLiAmPi has to be repeated for the new placement
  before any biological claim is carried over.
- **Memory, and it will be worse than last time.** Getting `cmalign` to fit took one CPU
  and `--cmalign_mxsize 4096` on our own reference package
  ([`TROUBLESHOOTING.md` §4](TROUBLESHOOTING.md)). The DREAM reference package is
  **larger**, so those settings are a floor, not a recipe. Plan for a machine with more
  RAM, or a cloud instance, rather than assuming the laptop configuration carries over.
- **Compute.** Placement is the expensive half of the pipeline. The original run
  accumulated 970 CPU hours on a laptop; budget accordingly.

---

| | |
|---|---|
| Written | 2026-08-30 |
| Sources checked, §3b and §3c added | 2026-09-24 |
| Status | not started; blocked on preconditions 1 and 2 |
| Reviewed by | *pending* |
