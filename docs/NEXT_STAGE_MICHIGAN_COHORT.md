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
| `slout_q20_Pool1_merged12_fnas/seqs.fastq` | 9.1 GB, 23 specimen labels |
| `slout_q20_Pool2_merged12_fnas/seqs.fastq` | 9.8 GB, 25 specimen labels |
| `1234_otu_table.biom` | the OTU table of the original QIIME 1 analysis: 97 columns, which are 96 specimens from 15 participants (5 to 8 specimens each) and one column labelled `Repetido` |

The two pools hold reads for 48 specimens (23 + 25). Whether all 48 are among the 96 of
the OTU table, and which participants they cover, has not been checked (§4,
precondition 2).

The two FASTQ files are outputs of QIIME 1's `split_libraries_fastq.py`: already
demultiplexed, already quality-filtered at q20, with forward and reverse reads **already
merged** (≈465 bp, consistent with a joined V3–V4 amplicon). Each record's label carries
the specimen and the barcode, in the form `P2.3.393_0 M01459:6:000000000-A7UGB:...
orig_bc=CTTGTA new_bc=CTTGTA bc_diffs=0`. The instrument run is `M01459:6:000000000-A7UGB`.

**These are the only reads that exist for these specimens.** The per-specimen, unmerged
FASTQ files that came off the sequencer are gone. That is a fact about the data, not a
search that can be repeated more thoroughly.

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

**Do not re-denoise. Place the reads directly on the reference package.**

MaLiAmPi assigns taxonomy by placing sequences on a reference phylogeny. Denoising is how
the Mexican cohort's run obtains the sequences it places; it is not what makes the
placements comparable. Two sets of sequences placed on the **same** reference package
land in the same space whatever produced them.

So, for the Michigan specimens:

1. Split each pool's `seqs.fastq` by specimen label into per-specimen files.
2. Dereplicate each specimen into unique sequences with counts. Keep the weights: they
   are what the abundance tables are built from.
3. Align and place those unique sequences on the reference package this project already
   built (`refpkg.tar.gz`, SHA-256 `2a3ce022…`), with the same `cmalign` and `pplacer`
   containers the run used ([`env/VERSIONS.md`](../env/VERSIONS.md)).
4. Classify and tally exactly as the documented run did, producing the same table shapes.

This is a different route, and the resulting tables must say so wherever they are used.
The two cohorts will be comparable **at the level of the reference tree** — taxa and
phylotypes — and not at the level of sequence variants, because one set is DADA2 output
and the other is dereplicated merged reads.

### What this route does not fix

- **Different error profiles.** The Michigan reads passed a q20 filter; the Mexican ones
  went through DADA2. Rare taxa and low-abundance calls are not equally trustworthy
  between the two. Any comparison of *rare* features across cohorts — a model that relies
  on them included — needs its own check, the same lesson the QIIME2 ↔ MaLiAmPi comparison
  produced ([`CONCORDANCE_QIIME2_MALIAMPI.md` §4](CONCORDANCE_QIIME2_MALIAMPI.md)).
- **Batch is confounded with cohort.** The Michigan specimens come from a different
  population and a separate sequencing run, unlike the twelve artificial `batch` groups of
  the Mexican run ([`RUN_MALIAMPI.md` §2](RUN_MALIAMPI.md)). Every difference between the
  cohorts, a change in a model's performance included, mixes population with sequencing
  and read processing; with no specimen sequenced in both, these data cannot tell them
  apart.

## 4. Preconditions, in order

| # | Task | Product that proves it is done |
|---|---|---|
| 1 | Establish the specimen ↔ participant link for the Michigan specimens, verified the way the Mexican one was. Their labels (`P2.3.393`) are not `Au###`, and the canonical map does not cover them: it is the Mexican cohort's map. | A map with the same guarantees as the canonical one, its own SHA-256 in `metadata/`, and a verification log. See [`CONCORDANCE_QIIME2_MALIAMPI.md` §6](CONCORDANCE_QIIME2_MALIAMPI.md) |
| 2 | Establish which participants the 48 specimens with reads belong to, and whether their metadata exist: **outcome** (term or preterm), **gestational week at sampling** and **maternal age** — the variables of the minimal adjustment, Approach 1, of the [analysis compendium](https://github.com/martinruhle/Mexican-PretermBirth-analysis#clinical-variable-sets). | The list of participants covered by the 48 specimens, with each of the three variables marked as present or absent, held with the project data like the map. Recorded here, counts only: participants covered, the range of specimens per participant, and how many participants have each variable |
| 3 | Split and dereplicate the pools (§3 steps 1–2). | Per-specimen unique sequences with weights, counted, and a record of how many reads each specimen contributed |
| 4 | Place and classify on the existing reference package (§3 steps 3–4). | An output directory with its own manifest under `metadata/`, and a run record written like [`RUN_MALIAMPI.md`](RUN_MALIAMPI.md) |
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

## 5. Open question

Whether to place the Michigan specimens on **our** reference package (as above) or on the
DREAM Challenge one depends on the decision in
[`NEXT_STAGE_DREAM_REFPKG.md` §3](NEXT_STAGE_DREAM_REFPKG.md); the "Michigan dataset" of
that section is the cohort described here. Whichever is chosen, a model is validated on
Michigan only with features from the reference package it was trained on: phylotype
identifiers do not transfer between packages
([`NEXT_STAGE_DREAM_REFPKG.md` §1](NEXT_STAGE_DREAM_REFPKG.md)). Placing twice is
cheap — the expensive half was denoising, which this route skips — but the two sets of
outputs must not be mixed. Decide the DREAM direction first, then place once, or place
twice and keep the outputs in separate directories with separate manifests.

---

| | |
|---|---|
| Written | 2026-09-24, as `NEXT_STAGE_OLD_RUN.md` |
| Revised | 2026-10-15: the specimens are a different cohort (Michigan), for external validation; preconditions 2 and 5 follow from that |
| Status | planned, not started |
| Reviewed by | *pending* |
