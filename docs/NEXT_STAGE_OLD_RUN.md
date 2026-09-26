# 🚧 Next stage — the earlier sequencing run

**Status: planned, not started.** What is settled is the constraint and the route. What
has not been done is any processing.

The cohort documented in this repository is one sequencing run: 111 specimens, `Au###`,
described in [`RUN_MALIAMPI.md`](RUN_MALIAMPI.md). An **earlier** run of the same study
exists, and the intention is to bring it into the same feature space, so that both can be
analysed together.

---

## 1. What survives of that run

Located and characterised on 2026-09-24. It is held with the project data, not in this
repository ([`DATA_ACCESS.md`](DATA_ACCESS.md)):

| | |
|---|---|
| `slout_q20_Pool1_merged12_fnas/seqs.fastq` | 9.1 GB, 23 specimen labels |
| `slout_q20_Pool2_merged12_fnas/seqs.fastq` | 9.8 GB, 25 specimen labels |
| `1234_otu_table.biom` | the OTU table of the original QIIME 1 analysis |

The two FASTQ files are outputs of QIIME 1's `split_libraries_fastq.py`: already
demultiplexed, already quality-filtered at q20, with forward and reverse reads **already
merged** (≈465 bp, consistent with a joined V3–V4 amplicon). Each record's label carries
the specimen and the barcode, in the form `P2.3.393_0 M01459:6:000000000-A7UGB:...
orig_bc=CTTGTA new_bc=CTTGTA bc_diffs=0`. The instrument run is `M01459:6:000000000-A7UGB`.

**These are the only reads that exist for that run.** The per-specimen, unmerged FASTQ
files that came off the sequencer are gone. That is a fact about the data, not a search
that can be repeated more thoroughly.

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
incomparability is the worst possible outcome for a study whose whole point is to pool
the two runs.

## 3. The route chosen

**Do not re-denoise. Place the reads directly on the reference package.**

MaLiAmPi assigns taxonomy by placing sequences on a reference phylogeny. Denoising is how
the current run obtains the sequences it places; it is not what makes the placements
comparable. Two sets of sequences placed on the **same** reference package land in the
same space whatever produced them.

So, for the earlier run:

1. Split each pool's `seqs.fastq` by specimen label into per-specimen files.
2. Dereplicate each specimen into unique sequences with counts. Keep the weights: they
   are what the abundance tables are built from.
3. Align and place those unique sequences on the reference package this project already
   built (`refpkg.tar.gz`, SHA-256 `2a3ce022…`), with the same `cmalign` and `pplacer`
   containers the run used ([`env/VERSIONS.md`](../env/VERSIONS.md)).
4. Classify and tally exactly as the documented run did, producing the same table shapes.

This is a different route, and the resulting tables must say so wherever they are used.
The two runs will be comparable **at the level of the reference tree** — taxa and
phylotypes — and not at the level of sequence variants, because one set is DADA2 output
and the other is dereplicated merged reads.

### What this route does not fix

- **Different error profiles.** The earlier reads passed a q20 filter; the current ones
  went through DADA2. Rare taxa and low-abundance calls are not equally trustworthy
  between the two. Any comparison of *rare* features across runs needs its own check —
  the same lesson the QIIME2 ↔ MaLiAmPi comparison produced
  ([`CONCORDANCE_QIIME2_MALIAMPI.md` §4](CONCORDANCE_QIIME2_MALIAMPI.md)).
- **Batch.** The two runs are genuinely different sequencing efforts, unlike the twelve
  artificial `batch` groups of the current run ([`RUN_MALIAMPI.md` §2](RUN_MALIAMPI.md)).
  Run-of-origin is a real covariate here and must be carried into any model.

## 4. Preconditions, in order

| # | Task | Product that proves it is done |
|---|---|---|
| 1 | Establish the specimen ↔ participant link for the earlier run, verified the way the current one was. Its labels (`P2.3.393`) are not `Au###`, and the canonical map does not cover them. | A map with the same guarantees as the canonical one, its own SHA-256 in `metadata/`, and a verification log. See [`CONCORDANCE_QIIME2_MALIAMPI.md` §6](CONCORDANCE_QIIME2_MALIAMPI.md) |
| 2 | Confirm whether the two runs share participants, and at which visits. | A statement, with counts, of how many participants and specimens each run contributes and how many overlap |
| 3 | Split and dereplicate the pools (§3 steps 1–2). | Per-specimen unique sequences with weights, counted, and a record of how many reads each specimen contributed |
| 4 | Place and classify on the existing reference package (§3 steps 3–4). | An output directory with its own manifest under `metadata/`, and a run record written like [`RUN_MALIAMPI.md`](RUN_MALIAMPI.md) |
| 5 | Check that the two runs are comparable where it is claimed they are. | A concordance report between the runs on shared participants if any exist, or on overall composition if none do — with an explicit verdict |

Precondition 1 is not optional and not a formality. The current run's specimen linkage
had to be rebuilt from count fingerprints because the labels could not be trusted
([`KNOWN_ISSUES.md`](../KNOWN_ISSUES.md) item 10). There is no reason to assume the older
labelling is in better shape, and the same fingerprint technique is available: the OTU
table of the original analysis is held alongside the reads.

## 5. Open question

Whether to place the earlier run on **our** reference package (as above) or on the DREAM
Challenge one depends on the decision in
[`NEXT_STAGE_DREAM_REFPKG.md` §3](NEXT_STAGE_DREAM_REFPKG.md). Placing it twice is
cheap — the expensive half was denoising, which this route skips — but the two sets of
outputs must not be mixed. Decide the DREAM direction first, then place once, or place
twice and keep the outputs in separate directories with separate manifests.

---

| | |
|---|---|
| Written | 2026-09-24 |
| Status | planned, not started |
| Reviewed by | *pending* |
