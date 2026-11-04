# 🚧 Next stage — the Michigan cohort, for external validation

**Status: planned, not started.** What is settled is the constraint and the route. What
has not been done is any processing.

The cohort documented in this repository is one sequencing run: 111 specimens, `Au###`,
described in [`RUN_MALIAMPI.md`](RUN_MALIAMPI.md). The specimens this document is about
belong to a **different cohort**, from Michigan, sequenced and processed on their own.
They do not add participants to this study. Their use is **external validation**: testing
whether what is learned on the Mexican cohort holds in an independent one. For that, both
cohorts have to be described in the same feature space, and the Michigan reads cannot
reach it through the pipeline this repository documents (§2).

---

## 1. What exists for these specimens

The reads were located and characterised on 2026-09-24; the OTU table, on 2026-10-13,
without opening the reads. They are held with the project data, not in this repository,
under the same rule as the Mexican cohort's data
([`DATA_ACCESS.md`](DATA_ACCESS.md#the-rule-this-repository-follows)):

| | |
|---|---|
| `slout_q20_Pool1_merged12_fnas/seqs.fastq` | 9.1 GB, 23 specimen labels — **truncated**: 9,124,577,280 bytes, an exact multiple of 64 KiB, and its last record is incomplete (35,115,491 lines, not a multiple of 4) |
| `slout_q20_Pool2_merged12_fnas/seqs.fastq` | 9.8 GB, 25 specimen labels, 9,533,104 complete records |
| `1234_otu_table.biom` | the OTU table of the original QIIME 1 analysis: 97 columns, which are 96 specimens from 15 participants (5 to 8 specimens each) and one column labelled `Repetido` |

The two pools hold reads for 48 specimens (23 + 25). All 48 are among the OTU table's 96
specimens, and which participants they cover is now established (§4, precondition 2).

The two FASTQ files are outputs of QIIME 1's `split_libraries_fastq.py`: already
demultiplexed, already quality-filtered at q20, with forward and reverse reads **already
merged** (≈465 bp, consistent with a joined V3–V4 amplicon). Each record's label carries
the specimen and the barcode, in the form `P2.3.393_0 M01459:6:000000000-A7UGB:...
orig_bc=CTTGTA new_bc=CTTGTA bc_diffs=0`. The two pools are two separate MiSeq runs, not
one: Pool 1 is `M01459:6:000000000-A7UGB`, Pool 2 is `M01459:4:000000000-A7Y0H`.

**These are the only reads available for these specimens in this project.** The
per-specimen, unmerged FASTQ files the sequencer produced are not available here. That is
a fact about what this project holds, not a search that can be repeated more thoroughly.

## 2. Why the documented pipeline cannot simply be pointed at them

MaLiAmPi's manifest takes one forward and one reverse file per specimen, and hands them
to DADA2. DADA2 is not a generic denoiser: it learns an error model from the quality
scores of **unmerged** reads, and merges the pair itself only after denoising each
direction. Feeding it reads that are already merged and already quality-filtered breaks
both assumptions at once:

- there is no reverse read to learn a reverse error model from;
- q20 filtering has already removed the low-quality observations the model is estimated
  on, so the model that is learned describes a censored sample.

Nothing in the pipeline would fail loudly. It would produce sequence variants, and they
would not be comparable with the 21,382 variants this repository documents. A silent
incomparability is the worst possible outcome for an external validation, whose whole
point is that a feature means the same thing in both cohorts.

## 3. The route chosen

**Not DADA2, but not no denoiser either. Denoise, then place on the reference package.**

MaLiAmPi assigns taxonomy by placing sequences on a reference phylogeny. Denoising is how
the Mexican cohort's run obtains the sequences it places; it is not what makes the
placements comparable, so a different denoiser is not a problem for comparability — only
DADA2 is unusable here, for the reason in §2. Dereplication by itself is not a substitute:
q20 filtering removes low-quality base calls but not the substitution noise that still
inflates the count of distinct sequences well past the number of real variants, so
dereplicated-but-undenoised sequences would swamp the placement step with noise the
Mexican cohort's table never had to carry. Two sets of sequences placed on the **same**
reference package land in the same space whatever produced them, provided each set was
denoised first.

So, for the Michigan specimens:

1. Split each pool's `seqs.fastq` by specimen label into per-specimen files.
2. Dereplicate each specimen into unique sequences with counts. Keep the weights: they
   are what the abundance tables are built from.
3. Denoise each specimen's dereplicated sequences with a denoiser built for already-merged,
   already-filtered reads (for example UNOISE3) — not DADA2, which needs unmerged pairs
   (§2).
4. Align and place the denoised sequences on the reference package this project already
   built (`refpkg.tar.gz`, SHA-256 `2a3ce022…`), with the same `cmalign` and `pplacer`
   containers the run used ([`env/VERSIONS.md`](../env/VERSIONS.md)).
5. Classify and tally exactly as the documented run did, producing the same table shapes.

This is a different route, and the resulting tables must say so wherever they are used.
The two cohorts will be comparable **at the level of the reference tree** — taxa and
phylotypes — and not at the level of sequence variants, because one set is DADA2 output
and the other is a different denoiser's output on already-merged, already-filtered reads.

### What this route does not fix

- **Different error profiles.** The Michigan reads passed a q20 filter and a denoiser of
  their own; the Mexican ones went through DADA2. Rare taxa and low-abundance calls are
  not equally trustworthy between the two. Any comparison of *rare* features across
  cohorts — a model that relies on them included — needs its own check, the same lesson
  the QIIME2 ↔ MaLiAmPi comparison produced
  ([`CONCORDANCE_QIIME2_MALIAMPI.md` §4](CONCORDANCE_QIIME2_MALIAMPI.md)).
- **Batch is confounded with cohort, not with population.** The Michigan specimens are
  Mexican, by the study's own investigators' account — a different cohort, sequencing run
  and read processing from the documented run, not a different population — unlike the
  twelve artificial `batch` groups of the Mexican run
  ([`RUN_MALIAMPI.md` §2](RUN_MALIAMPI.md)). Every difference between the two sets of
  specimens, a change in a model's performance included, still mixes cohort with
  sequencing and read processing; with no specimen sequenced in both, these data cannot
  tell them apart.

## 4. Preconditions, in order

| # | Task | Product that proves it is done |
|---|---|---|
| 1 | Establish the specimen ↔ participant link for the Michigan specimens, verified the way the Mexican one was. Their labels (`P2.3.393`) are not `Au###`, and the canonical map does not cover them: it is the Mexican cohort's map. | A map with the same guarantees as the canonical one, its own SHA-256 in `metadata/`, and a verification log. See [`CONCORDANCE_QIIME2_MALIAMPI.md` §6](CONCORDANCE_QIIME2_MALIAMPI.md) |
| 2 | Establish which participants the 48 specimens with reads belong to, and whether their metadata exist: **outcome** (term or preterm), **gestational week at sampling** and **maternal age** — the variables of the minimal adjustment, Approach 1, of the [analysis compendium](https://github.com/martinruhle/Mexican-PretermBirth-analysis#clinical-variable-sets). | The list of participants covered by the 48 specimens, with each of the three variables marked as present or absent, held with the project data like the map. Recorded here, counts only: participants covered, the range of specimens per participant, and how many participants have each variable |
| 3 | Split, dereplicate and denoise the pools (§3 steps 1–3). | Per-specimen denoised sequences with weights, counted, and a record of how many reads each specimen contributed |
| 4 | Place and classify on the existing reference package (§3 steps 4–5). | An output directory with its own manifest under `metadata/`, and a run record written like [`RUN_MALIAMPI.md`](RUN_MALIAMPI.md) |
| 5 | Check that the two cohorts' tables are comparable where the validation will claim they are. | A concordance report on overall composition between the cohorts, which share no participants, with an explicit verdict |

Precondition 1 is not optional and not a formality. The Mexican cohort's specimen linkage
had to be rebuilt from count fingerprints because the labels could not be trusted
([`KNOWN_ISSUES.md`](../KNOWN_ISSUES.md) item 10). There is no reason to assume the
Michigan labelling is in better shape, and the same fingerprint technique is available:
the OTU table of the original analysis is held alongside the reads.

Precondition 2 decides whether there is a validation at all. A specimen without a known
outcome cannot test a prediction, and an Approach 1 model cannot be applied to a specimen
that lacks gestational week or maternal age. The OTU table covers 15 participants; how
many of them the 48 specimens with reads reach, and with which of the three variables, is
the size of the validation, and it can be known before any read is processed.

**Precondition 2, counted.** `MP1.txt` — the QIIME 1 participant↔specimen map, held with the
reads and the OTU table, downloaded from an email the study's investigators sent with the
project data (SHA-256 `7263921679fb…`) — assigns the OTU table's 96 specimens (plus its
`Repetido` column) to **15** participants, 5 to 8 specimens each, each with one outcome: 9
term, 6 preterm. All 48 of the pool labels (Pool 1's 23, Pool 2's 25) are present, character
for character, among the OTU table's 97 columns (SHA-256 `a3fb428783c4…`), and they reach
**8** of the 15 participants, 4 to 8 specimens each — 3 term, 5 preterm, by `MP1.txt`'s own
outcome for each. Gestational week at sampling and maternal age are present for **none** of
the 15: neither file carries either variable, the OTU table has no per-column metadata at all
(QIIME 1.8.0, 2014), and the digit right after a specimen's `N`/`P` letter, which looks
consistent with the trimester of collection, has not been confirmed against an independent
source. The per-participant list these counts come from — specimen counts, outcome, and the
two missing variables, marked absent for all 15 — is held with the project data
(`michigan_cohort_coverage_48_specimens.csv`, SHA-256 `54f0c20c7580…`), not in this
repository. A request for the two missing variables and for the unmerged per-specimen reads
has already gone to the study's investigators; nothing has come back yet.

Two things the count turned up for precondition 1 to resolve: eight of `MP1.txt`'s 96 specimen
IDs have a missing or doubled digit (for example `N.2.2697`, `P3.3739`) and need normalising
before they can be matched by string; and one of the eight participants has two specimens
that the OTU table and Pool 2's reads label with the opposite outcome-letter from the one
`MP1.txt` gives the rest of her specimens. `MP1.txt`'s own `Treatment` column — the one this
count uses — is unanimous across all seven of her specimens, so this is a labelling
disagreement between sources to resolve when the map is built, not an outcome in doubt. Both
points, with the specific specimen IDs, are noted in `michigan_cohort_coverage_48_specimens.csv`.

## 5. Open question

Whether to place the Michigan specimens on **our** reference package (as above) or on the
DREAM Challenge one depends on the decision in
[`NEXT_STAGE_DREAM_REFPKG.md` §3](NEXT_STAGE_DREAM_REFPKG.md); the "Michigan dataset" of
that section is the cohort described here. Whichever is chosen, a model is validated on
Michigan only with features from the reference package it was trained on: phylotype
identifiers do not transfer between packages
([`NEXT_STAGE_DREAM_REFPKG.md` §1](NEXT_STAGE_DREAM_REFPKG.md)). Denoising happens once
either way; placing the same denoised sequences on a second reference package afterwards
is the comparatively cheap part. Decide the DREAM direction first, then place once, or
place twice and keep the outputs in separate directories with separate manifests.

---

| | |
|---|---|
| Written | 2026-09-24, as `NEXT_STAGE_OLD_RUN.md` |
| Revised | 2026-10-15: the specimens are a different cohort (Michigan), for external validation; preconditions 2 and 5 follow from that |
| Revised | 2026-11-04: precondition 2 counted — 8 of the 15 participants are reached by the 48 specimens with reads, none of the 15 has gestational week at sampling or maternal age |
| Revised | 2026-11-04: two MiSeq runs, not one; Pool 1's copy is truncated; the route denoises before placing, it does not skip denoising; the specimens are Mexican, not a different population |
| Status | planned, not started |
| Reviewed by | *pending* |
