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
to the DREAM Hispanic subgroup, and the reverse. That subgroup is **38 participants**:
those recorded as "Hispanic or Latino" in the subject table of ImmPort study SDY2187
(release DR61), all of them in the Challenge's validation set, and 15 of them in the study's
"Preterm Validation" arm; the earlier version of that set had 42 (§3b). At phylotype level,
either direction requires both cohorts to be described in **one** phylotype space; at genus
and species level it does not, because names transfer. On whose reference package that one
space is built is the choice §3 records.

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

There are two ways to put both cohorts in one feature space. They lead to **different
feature spaces**, and the features they produce **cannot be mixed in the same model**.

**Option A — place our sequence variants on the DREAM reference package.**
What the objective as first written asked for. Our data land directly in the
Challenge's feature space, so the models published with the Challenge apply without
retraining. Requires obtaining their reference package.

**Option B — place the DREAM sequence variants on our reference package.**
Needs the nucleotide sequences of the Challenge's variants, not their raw reads, and the
Challenge's two sets differ in whether they carry them (§3b). The **training set** can be
placed without asking anyone: `Training.zip` carries the sequences of its 53,129 variants
(`sv_counts/sv.fasta`). The **validation set** cannot: neither version of `Validation.zip`
carries the sequences of its 2,358 variants, and that set is where every participant with a
recorded ethnicity is, the 38 Hispanic participants included. The phylotypes this produces
are ours, **not** the Challenge's, so a published Challenge model built on phylotype
features cannot be applied to them.

> **This is a live inconsistency in the project's own plans, not a hypothetical.** The
> earlier plan for the Michigan dataset was Option B — place Michigan on our reference
> package. The objective as written now is Option A. Changing direction is legitimate;
> running both and mixing the outputs is not. **Decide which is the main line before any
> code is written**, and record the decision here. **Decided on 2026-10-15; see below.**

**Decision, 2026-10-15.** Both directions are used, each for what the other cannot do, and
their outputs are never mixed: separate directories, separate manifests, never in the same
model.

- **Option B is the main line.** Our cohort's phylotypes are cut from its placements on our
  own reference package and can be generated now, both for the internal analysis and as the
  space in which this project's models are validated at phylotype level. The Michigan
  cohort is placed once, on the same package, by the route of
  [`NEXT_STAGE_MICHIGAN_COHORT.md` §3](NEXT_STAGE_MICHIGAN_COHORT.md). The Challenge's
  training set can be placed on it now, directly with `cmalign` and `pplacer` as in §3c.
  Its validation set can be reached at phylotype level only if the authors send the
  sequences of its 2,358 variants.
- **Option A is a second line, conditional on the authors sending their reference
  package.** It is kept for what Option B cannot do: applying the Challenge's own models to
  our data, which use phylotype features (checked on 2026-10-21; see the table at the end of
  this section), and reaching the
  validation set at phylotype level if its sequences do not arrive. Michigan is placed on
  that package too only if this line needs it. None of our 21,382 variants is identical to
  any of the Challenge's 53,129. Most of the 15,343 training variants that have a phylotype
  are V4-length (median 253 bp), though, and 568 of them occur, base for base and in the
  same orientation, inside variants of ours that carry 91.5 % of our reads. Looked up
  through `pt.*.csv`, they point to a single phylotype for 45 % of our reads at distance
  0.1, 68 % at 0.5 and 88 % at 1.0 (checked on 2026-10-15). That is a partial way into the
  Challenge's numbering without the package, coarser the more of our reads it covers;
  whether it can stand in for placement has not been evaluated.
- **Genus, species and VALENCIA community state types need neither option.** Names transfer
  (§1), and both archives carry genus- and species-level tables
  (`taxonomy/taxonomy_relabd.genus.csv`, `taxonomy_relabd.species.csv`), labelled like
  ours by MaLiAmPi from the NCBI taxonomy, though not necessarily from the same release of
  it. Comparing them takes a crosswalk of names, not a reference package. This is the
  comparison §6 holds in reserve, and it can start now: for our cohort, for both sets of
  the Challenge, the 38 Hispanic participants included, and, once its reads are processed,
  for Michigan. On our side it uses the MaLiAmPi tables; the QIIME2 tables of the published
  analysis are labelled from SILVA
  ([`CONCORDANCE_QIIME2_MALIAMPI.md`](CONCORDANCE_QIIME2_MALIAMPI.md) measures how far the
  two agree).

**Why B is the main line.** It is the only complete phylotype-level route that waits on no
one. Without any reply it already puts our cohort, Michigan and the Challenge's training set
in one space; without the package, Option A can place neither of our cohorts in the
Challenge's, and the lookup above reaches only part of our reads. For the Hispanic subgroup
at phylotype level the two depend on the authors equally, A on the package and B on 2,358
sequences, and the reminder asks for either. Validating this project's own models needs one
shared space, not the Challenge's; only the Challenge's own models need theirs, and almost all
of the best-placed ones do (table below). The known weakness of B is coverage:
our package was recruited for our own variants (5,540 reference sequences,
[`REFPKG_PROVENANCE.md`](REFPKG_PROVENANCE.md)), so Challenge variants from taxa absent from
our cohort will be placed far from any reference. How much of the training set's reads our
package places and classifies has to be measured before any Challenge phylotype from this
line is used.

**What is missing for each.** Option A: the Challenge's reference package, which is not
published (§3b); it was requested from the authors on 2026-09-24, with a reminder on
2026-10-15, and whether the package alone is enough was part of the same request. Option B:
nothing for our cohort, Michigan or the training set; for the validation set, the sequences
of its 2,358 variants, which the reminder asks for as an alternative. Genus and species:
nothing beyond the crosswalk.

**Our phylotypes, and what a switch would redo.** Phylotype binning of our cohort at 0.1,
0.5 and 1.0 can go ahead on our package. Because the Challenge's training set and Michigan
join this space later, the binning has to record how variants placed afterwards are
assigned to the existing phylotypes, as the Challenge did for its validation set (§3b);
binning all the sets together afterwards could renumber them. If the main line ever moved
to Option A (for instance, if the package arrives, the validation sequences do not, and the
Hispanic subgroup at phylotype level becomes the priority), the following would be redone:
the placement of our 21,382 variants and of Michigan on the Challenge's package, the
phylotypes in the Challenge's numbering, VALENCIA on the species tables that placement
yields, and every model fitted on phylotype features. The genus- and species-level work
would stand.

The rest of this document, from §3b on, describes the Option A line: where its reference
package is not, what the pipeline can take, and what the line would require if it runs.
§3b also bears on Option B where it says so, and the direct placement of §3c is how Option
B places the training set. The Option B line and the genus- and species-level comparison
have no plan of their own yet.

### The Challenge's winning models: what they take as input, and where they are

Checked on 2026-10-21, to settle whether the Option A line is needed. Every entry below was
read on the page it cites (links after the table); what no opened page states is marked
*not verified*. Sources: the article ([Golob et al. 2024][paper], *Cell Rep Med*
5(1):101350), the [2025 notice][notice] published with it (doi 10.1016/j.xcrm.2025.102428)
and its updated Document S1 ([Tables S1–S5][s1]), the Challenge's
[final results][results] (Synapse tables `syn33100130` for sub-challenge 1 and `syn33100594`
for sub-challenge 2), each team's write-up project, and the GitHub repositories they link.
The submitted Docker images were not pulled: pulling one needs a Synapse login
([registry documentation][registry]), and running third-party code was outside this check.
The Challenge data files on local disk were not used.

**Two rankings exist.** The 2025 notice removed 12 individuals who were in both the training
and the validation data (study S went from 86 to 74 participants) and re-scored every
submission; Tables S2 and S3 now carry the original rank ("previous") and the new one
("updated"). The original ranks are the ones in the Synapse tables. Both are given, as
original → 2025. Sub-challenge 1 (SC1) predicts delivery before 37 weeks from specimens
collected up to week 32; sub-challenge 2 (SC2) predicts delivery before 32 weeks from
specimens up to week 28 ([task definitions][tasks]). Each submission returned **one
prediction per participant** ([submission format][submit]); how specimens were combined was
left to each team. Scores are mean bootstrapped AUROC and AUPRC on the validation studies W
and S (1,000 resamples by pregnancy).

The table covers every team placed in the top three of either sub-challenge under either
ranking, plus CompD (the only other model found that needs no tree feature; SC1 15th in 2025,
within the Bayes-factor < 20 set of Table S4), the organizers' ensemble, and the organizers'
example models. Abbreviations: **PT** phylotypes at the distances given (0.1, 0.5, 1.0);
**PD** the phylogenetic alpha-diversity metrics of the Challenge's `alpha_diversity.csv`
(balance-weighted PD, phylogenetic entropy, quadratic, rooted and unrooted PD); **div**
Shannon and inverse Simpson from the same file; **CST** VALENCIA community state types.
**No model in the table is known to use KRD** (the Kantorovich–Rubinstein distances; for
@polalawang the write-up does not say); KBJ's write-up says it left them out because they
cannot be computed for a test set.

| Team (write-up) | Rank, original → 2025 | Features | Needs the Challenge's tree | Code · fitted model · licence | Trained on | Validation AUROC / AUPRC, original → 2025 |
|---|---|---|---|---|---|---|
| UWisc-Madison ([`syn34232349`][w-uwisc]) | **SC1 1 → 1**; SC2 26 → 13 | Family, genus and species read counts (CLR); CST and subCST; PT 0.5 and 1.0 (CLR); PD; div; age, collection week, race. Two LightGBM models blended per specimen by sequencing depth and collection week | **Yes**: PT and PD | No source published; Docker image `syn34232353` only. Fitted model: inside the image, *not verified*. No licence stated | All nine training studies, specimens ≤ 32 wk; the second model on study G only | SC1 0.688 / 0.575 → 0.678 / 0.551 |
| AI4knowledgeLAB ([`syn35802768`][w-ai4k]) | SC1 2 → 4; **SC2 3 → 4** | No taxonomy; CST; PT 0.1, 0.5 and 1.0 (one random forest per distance); PD; div; collection week, race, ethnicity | **Yes**: PT and PD | Source in Synapse folders `syn37129171` (SC1) and `syn37129925` (SC2); fitted models in Docker repositories `syn36400367` and `syn36448011`, contents *not verified*. Downloads need a Synapse login. No licence stated | Training set, specimens ≤ 32 wk (SC1) or ≤ 28 wk (SC2) | SC1 0.641 / 0.484 → 0.642 / 0.448; SC2 0.831 / 0.343 → 0.838 / 0.41 |
| IBB_UT ([`syn34085067`][w-ibb]) | **SC1 3 → 28**; SC2 15 → 17 | **Genus and species relative abundance** (591 features plus 40 principal components); **CST**. No PT, no diversity, no metadata (collection week only to keep weeks 9–32). Random forest | **No** | Exploratory R code on [GitHub][gh-ibb]; Docker repository `syn36382380`. Fitted model not on GitHub (the code reads `.rds` files the repository does not hold). No licence file | Training set, specimens in weeks 9–32. How specimens become one prediction per participant: *not verified* | SC1 0.640 / 0.526 → 0.571 / 0.45 |
| DMIS_2022_PTB ([`syn36245853`][w-dmis]) | SC1 5 → **2**; SC2 22 → 24 | Taxonomy (rank *not verified*); PT (distance *not verified*); alpha diversity (which metrics *not verified*); collection week, normalised read count. CST not among the inputs listed. Random-forest ensemble | **Yes**: PT; PD *not verified* | Docker images only (`syn36448001` SC1, `syn36448401` SC2). No licence stated | Training set after read-count and outlier filtering | SC1 0.634 / 0.470 → 0.657 / 0.453 |
| UMICH_DREAM_PTB ([`syn33585048`][w-umich]) | SC1 9 → **3** (Table S2; the notice says "into the top two"); SC2 6 → 10 | No taxonomy; CST, VALENCIA score and their interaction; PT 0.1; PD (balance-weighted PD, phylogenetic entropy, rooted PD); Shannon; collection week, race. Extremely randomized trees | **Yes**: PT and PD | Docker images only (`pt:v3.3` SC1; `ept:v1.0` SC2, `syn36336742`). No licence stated | Training set, 70/30 split by participant | SC1 0.623 / 0.540 → 0.655 / 0.555 |
| Techtmann Lab ([`syn35877342`][w-tech]) | SC1 15 → 14; **SC2 1 → 1** | No taxonomy; CST; PT 0.1; PD; div; race, collection week. Random forest, scikit-learn defaults | **Yes**: PT and PD | Source on [GitHub][gh-tech]; Docker repository `syn36511607`. Fitted model not on GitHub. No licence file | Training set, all specimens (no week filter in the training script) | SC2 0.868 / 0.446 → 0.92 / 0.553 (sensitivity 0 at the 0.5 threshold in both) |
| KBJ ([`syn35594394`][w-kbj]) | SC1 4 → 9; **SC2 2 → 2** | Genus relative abundance; CST; PT 0.1; **the Challenge's own sequence variants**, indexed by its variant number; PD; div; race. 300 features per block chosen by mRMR; soft-voting ensemble | **Yes**: PT, PD and the Challenge's variant identifiers | Source on [GitHub][gh-kbj] (archived). **Fitted models public**: `preterm/Models/model_1–5.save` and `early_preterm/Models/models_1–5.save` (joblib); not downloaded. No licence file | Training set, filtered by collection week (window not stated) | SC2 0.841 / 0.270 → 0.901 / 0.316 |
| @polalawang ([`syn33064784`][w-pola]) | SC1 31 → 31; SC2 4 → **3** | Taxonomy (rank not stated) and PT (distance not stated), both normalised with RioNorm2; race. CST, diversity and KRD: *not verified* (the write-up does not mention them). Soft-voting ensemble | **Yes**: PT | The GitHub repository the write-up links returns 404; Docker repository `syn35545064`. No licence stated | Training set (details *not verified*) | SC2 0.827 / 0.297 → 0.876 / 0.337 |
| CompD ([`syn36334086`][w-compd]) | SC1 20 → 15; SC2 25 → 26 | **Genus read counts** (CLR); **CST** scores; trimester and maternal-age flags. Autoencoder, then random forest | **No** | Docker images only (`syn36472365` SC1). No licence stated | Studies C, E, G, H, I and J | SC1 0.586 / 0.467 → 0.604 / 0.467 |
| Organizers' ensemble (article, Figure 5) | Not ranked | Mean of the predictions of every team whose Bayes factor against the top model is < 20; the features are those of its members. All five SC2 members in the 2025 Table S5 (Techtmann, KBJ, @polalawang, AI4knowledgeLAB, Clague VT.TP) use PT | **Yes**, through its members | No code and no fitted ensemble found (article, the organizers' GitHub accounts, Zenodo) | Its members' training | 0.74 (SC1) and 0.91 (SC2), AUROC only, original version; the 2025 values were not obtained |
| Organizers' examples: R sample model ([GitHub][gh-r]) and Python notebook ([GitHub][gh-py]) | Not ranked. The scored baseline image (`ptb-dream-example`) is SC1 29 → 7, SC2 11 → 15; that it is either example is *not verified* | PT only: 0.5 (R); 0.1, 0.5 and 1.0 (Python). Random forests | **Yes**: PT | Code public. The R repository holds a `model.rds` whose training data are *not verified*; the notebook's fitted models are not in its repository. No licence on either | Training set (R: *not verified*; Python: 70/30 split of the release of 2022-05-27) | Baseline image: SC1 0.561 → 0.617; SC2 0.768 → 0.767 (AUROC) |

Of the other teams whose write-ups were read and that are not in the table, IBSE_IITM (SC2
5 → 5), Clague VT.TP (SC2 7 → 6) and USF biostat (SC2 8 → 9) use PT; @yuanfang.guan (SC1
6 → 10) does not say which tables it used. Team Wallac (SC1 5th in 2025) was not read. In the article's own
analysis of the best models, phylotypes were used by 2 of 3 in SC1 and 8 of 8 in SC2, and all
7 SC2 models that used alpha diversity were sensitive to rooted PD. No write-up read reports
training on anything but the Challenge's training set, and no licence was found for any
team's code or model (none in any write-up read; GitHub reports none for the three team
repositories; the Docker images were not inspected).

**What can be applied to our cohort now: none of them, as published.**

- **Seven of the eight top-three teams, and the ensemble, need features defined on the
  Challenge's tree**: phylotypes in its numbering (all seven) and, for most, phylogenetic
  alpha diversity computed on that tree. Our run has alpha diversity and KR distances
  ([`RUN_MALIAMPI.md`](RUN_MALIAMPI.md)), but computed on our own tree, which makes them
  different quantities. KBJ also needs the Challenge's variant identifiers; none of our 21,382
  variants is identical to any of its 53,129 (above), so that block would be zero for every
  specimen of ours.
- **The two models that need no tree, IBB_UT and CompD, use only inputs we can produce** in
  kind: genus and species abundance (already in `tallies_wide.genus` and
  `tallies_wide.species`), CST (once VALENCIA is run, item 2 below) and, for CompD, simple
  metadata. **Neither fitted model is published**: IBB_UT's repository lacks its `.rds` files
  and CompD published no source. If they exist, they are presumably only inside Docker images
  that need a Synapse login (*not verified*: the images were not pulled). IBB_UT also fell from 3rd to 28th in SC1 under the 2025 re-scoring
  (AUROC 0.640 → 0.571).
- **The only published fitted team model found, KBJ's, depends on the Challenge's space more
  than any other**: besides phylotypes and phylogenetic diversity, it alone needs the
  Challenge's variant identifiers. (The organizers' R example also commits a fitted model,
  on phylotypes only.)
- **No licence was found for any of them**, so using any of them needs the authors' permission. The
  Challenge's data were released [for use within the Challenge only][terms], to be destroyed
  when it ended; whether models trained on them may be used outside it is not stated on any
  page read, and is a question for the organizers.

**What applying any of them would take**, beyond the reference package and the model itself:

1. **A crosswalk of names.** A model's taxonomic input is a fixed list of Challenge column names
   (training and validation headers were made identical in the [data update of
   2022-08-22][update]; the [data description][files] lists 1,083 genus and 2,119 species
   columns). Our 547 genus and 913 species
   labels, compound labels included, have to be mapped onto them, in the form each model
   expects: relative abundance (IBB_UT, KBJ) or read counts with CLR (UWisc-Madison, CompD).
2. **CST on our species table.** VALENCIA has not been run on our MaLiAmPi tables in this
   repository (its commit and environment are pinned in [`env/VERSIONS.md`](../env/VERSIONS.md)). Every model in the
   table uses CST except DMIS_2022_PTB (not among its listed inputs) and the organizers'
   examples; for @polalawang it is *not verified*.
3. **The collection window.** SC1 models were scored on specimens up to week 32 and SC2 models
   on specimens up to week 28; ours have to be filtered the same way, and how many of our 43
   participants keep a specimen in each window has not been counted.
4. **One prediction per participant, by each model's own rule**: weighted mean by collection
   week (UWisc-Madison), mean (DMIS_2022_PTB, UMICH_DREAM_PTB, CompD), maximum (Techtmann
   Lab), mean or maximum depending on the submission (AI4knowledgeLAB; which one was scored is
   *not verified*), averaging features before predicting (KBJ). The rules of IBB_UT and
   @polalawang are *not verified*.
5. **The outcome.** SC2 predicts delivery before 32 weeks. Whether our cohort has enough early
   preterm deliveries to evaluate it has to be checked before SC2 models are considered; with
   14 preterm deliveries among 43 participants, even SC1 will have a wide interval.
6. **If a recipe is retrained instead of reused**, the result is not the published model and its
   reported performance does not carry over. Outside the Challenge, the training data available
   are ImmPort SDY2187: studies A–G, 616 of the 1,268 participants; studies H (114) and I (538)
   need dbGaP (Table S1). Every team model above whose training data is described had studies
   H and I in it (CompD names them; the others used the training set as distributed, filtered
   by week; UWisc-Madison's second model used study G only); for @polalawang and the R
   example this is *not verified*. A refit on ImmPort alone sees about half of the
   participants they saw.

**What this means for the Option A line.** It stays. It could be dropped only if no winning
model used features of the Challenge's tree and the validation sequences arrived; the first
condition fails for every top-three team except IBB_UT, and for the ensemble. Option A is the
only route by which those tree-dependent models could be run on our data; IBB_UT and CompD
could run on our genus and species tables without it, if their fitted models were obtained.
The reference package alone is not enough, though. Running any tree-dependent model also
needs: the rule by which the Challenge assigned new variants to its phylotypes (as it did for
its validation set, §3b), PD computed with the same tool on the same tree, the fitted models
(presumably inside Docker images behind a Synapse login, *not verified*; KBJ's are public),
and the authors' permission to use them. These belong in the
request already made to the authors. The genus- and species-level comparison needs neither
option: the IBB_UT and CompD recipes can be refitted there, with the limits of item 6.

[paper]: https://pmc.ncbi.nlm.nih.gov/articles/PMC10829755/
[notice]: https://pmc.ncbi.nlm.nih.gov/articles/PMC12765831/
[s1]: https://ars.els-cdn.com/content/image/1-s2.0-S2666379123005670-mmc1.pdf
[results]: https://repo-prod.prod.sagebase.org/repo/v1/entity/syn26133770/wiki/619526
[tasks]: https://repo-prod.prod.sagebase.org/repo/v1/entity/syn26133770/wiki/618024
[submit]: https://repo-prod.prod.sagebase.org/repo/v1/entity/syn26133770/wiki/618028
[terms]: https://repo-prod.prod.sagebase.org/repo/v1/entity/syn26133770/wiki/618022
[update]: https://repo-prod.prod.sagebase.org/repo/v1/entity/syn26133770/wiki/618707
[files]: https://repo-prod.prod.sagebase.org/repo/v1/entity/syn26133770/wiki/618025
[registry]: https://docs.synapse.org/docs/Synapse-Docker-Registry.2011037752.html
[w-uwisc]: https://repo-prod.prod.sagebase.org/repo/v1/entity/syn34232349/wiki
[w-ai4k]: https://repo-prod.prod.sagebase.org/repo/v1/entity/syn35802768/wiki
[w-ibb]: https://repo-prod.prod.sagebase.org/repo/v1/entity/syn34085067/wiki
[w-dmis]: https://repo-prod.prod.sagebase.org/repo/v1/entity/syn36245853/wiki
[w-umich]: https://repo-prod.prod.sagebase.org/repo/v1/entity/syn33585048/wiki
[w-tech]: https://repo-prod.prod.sagebase.org/repo/v1/entity/syn35877342/wiki
[w-kbj]: https://repo-prod.prod.sagebase.org/repo/v1/entity/syn35594394/wiki
[w-pola]: https://repo-prod.prod.sagebase.org/repo/v1/entity/syn33064784/wiki
[w-compd]: https://repo-prod.prod.sagebase.org/repo/v1/entity/syn36334086/wiki
[gh-ibb]: https://github.com/sadegh65v/PTB_IBB_UT
[gh-tech]: https://github.com/abby-franklin811/ML-PTB
[gh-kbj]: https://github.com/qoeogns09/Preterm_Birth_Prediction_Microbiome_DREAM_Challenge_KBJ
[gh-r]: https://github.com/Sage-Bionetworks-Challenges/mod-microbiome-r-sample-model
[gh-py]: https://github.com/jgolob/ptb_microbiome_samples

Synapse pages are rendered by JavaScript; the `repo-prod` links above are the public API
addresses that return the same wiki text without a login.

## 3b. Where the DREAM reference package is not

Checked on 2026-09-24; the study archives, on 2026-10-12. Recorded because a dead end that
is not written down gets searched again:

| Source | What is actually there |
|---|---|
| `zenodo.org/records/8329650` | The **source code** of MaLiAmPi v3.5.0, "Manuscript and PTB Dream challenge release", published 2023-09-08. Not a reference package. Useful for a different reason: our own run used a clone at tag `v3.5.0`, the same code ([`RUN_MALIAMPI.md` §4](RUN_MALIAMPI.md)) |
| `doi.org/10.5281/zenodo.10015300` — what the paper's key resources table cites as "MaLiAmPi" | Resolves to **jgolob/arf** v0.1, the ARF allele-filtering tool, not MaLiAmPi. The same ARF whose release we used to build our own package ([`REFPKG_PROVENANCE.md`](REFPKG_PROVENANCE.md)). The DOI printed next to "MaLiAmPi" resolves to ARF; the MaLiAmPi release is record `8329650`, above |
| Golob et al. 2024, *Cell Rep Med* 5(1):101350, "Data and code availability" (pp. 17–18) | Lists the nine source studies, the harmonized data (March of Dimes database, study **SDY2187**, via pretermbirthdb.org), the VMAP viewer, and the MaLiAmPi code. **No reference package is deposited anywhere in the list** |
| Synapse `syn26133770` | The Challenge project exists and its wiki is public; registration is closed and the data sit behind registration. Nothing in the public wiki mentions a reference package |
| ImmPort study **SDY2187**, release DR61: the archive downloaded from the study page on 2026-09-24 (`immport_SDY2187_20260924_1637.zip`, 1.1 MB, SHA-256 `a589ff99bad36261…`) | Only the release's **metadata package**: ImmPort's own tables for the study (subjects, arms, links, publications) and a "MaLiAmPi protocol" file that is a single link to `github.com/jgolob/maliampi`. The study data are separate study files, listed in the package manifest but not part of the archive: `Training.zip` (47 MB, MD5 `cfed9839b8636352c910789fe5757863`), `Validation.zip` (3.2 MB, MD5 `ce12eec5a51d4cf7db67dfebc9850b88`, "Updated version: 12/13/2024") and a participant-ID mapping. The study-files page still offers the earlier `Validation.zip` (3.5 MB, dated 2023-11-30) next to the current one (dated 2025-01-09). On 2026-10-12 the download page offered the same DR61 release files, identical in size and MD5 to the ones in this archive. The subject table (750 participants) records ethnicity as "Hispanic or Latino" for 38 and "Not Hispanic or Latino" for 95, all in the two validation arms; the other 617 are "Not Specified", among them all 616 in the training arms |
| Synapse wiki `618025` of `syn26133770`, "Data Description": the page ImmPort links from SDY2187 as "README and Dictionary for data files" | Describes the contents of `Training.zip` and `Validation.zip` file by file: alpha diversity, VALENCIA community state types, `metadata.csv`, KRD distances, phylotype tables at the three distances, the mapping of each sequence variant to its phylotype (`pt.1e-1.csv`, `pt.5e-1.csv`, `pt.1e0.csv`), reads per specimen and sequence variant (`sp_sv_long.csv`) and a taxonomic assignment per variant (`sv_taxonomy.csv`). **No reference package, tree or placement file, and no file with the variants' nucleotide sequences.** The list is not a full inventory: it names 23 files and leaves out `sv_counts/sv.fasta`, `phylotypes/pt_sp.*.csv`, `cst_valencia_dummies.csv` and `metadata_normalized.csv`, which `Training.zip` contains (next row) |
| `Training.zip`, the version in the DR61 manifest (MD5 identical) | 29 files: the 23 in the dictionary, `metadata_normalized.csv`, `cst_valencia_dummies.csv`, three `pt_sp.*.csv` (a species label per phylotype) and **`sv_counts/sv.fasta`, the nucleotide sequences of 53,129 variants** (`combinedsv___#####`), among them all 15,343 that appear in the training tables. **No reference package, tree or placement file.** Its `metadata.csv` covers 616 participants, with ethnicity "Unknown" for all of them |
| `Validation.zip`, the current version (dated 2025-01-09; the one in the DR61 manifest, MD5 identical) | 31 files: the 23 in the dictionary, `metadata_normalized.csv`, `cst_valencia_dummies.csv` and six `taxonomy_*.full.csv`; **no `sv.fasta`** and no `pt_sp.*.csv`. Its 2,358 variants have their own identifiers (`validation_sv_#####`), and `pt.*.csv` assigns them to phylotypes in the training numbering: at distance 0.1 they fall into 725 phylotypes, 672 of which also appear in the training tables. **No reference package, tree or placement file.** Its `metadata.csv` covers 134 participants and has no ethnicity column |
| `Validation.zip`, the earlier version (dated 2023-11-30; 3.7 MB, MD5 `d21489d51cce74d4672a9ec3aaae6d91`) | The same 31 file names, also without `sv.fasta`. 148 participants: the 134 above and 14 that the update removed. Its `metadata.csv` still has an ethnicity column (42 "Hispanic or Latino", 105 "Not Hispanic or Latino", 1 "Unknown") |

What the Challenge distributed to participants were **phylotype and taxonomy tables**, not
the package they were derived from. That is consistent: participants never needed to place
anything themselves. Two facts from these files bear on both options in §3:

- The phylotypes are groups of the Challenge's own variants ("Phylotypes were generated by
  clustering amplicon sequence variants at three phylogenetic distances"), and `pt.*.csv`
  records which variant went to which group. The validation variants, which have
  identifiers of their own, were assigned to phylotypes of the same numbering.
- The sequences of the training variants are distributed (`sv.fasta`); those of the
  validation variants are not, in either version. Option B can therefore
  reach the training set without raw reads, but not the validation set, which is where
  every participant with a recorded ethnicity is.

Ethnicity, by source. The current `metadata.csv` has no ethnicity column, so ImmPort's
subject table (DR61) is the only current source: 38 "Hispanic or Latino", 95 "Not Hispanic
or Latino" and 1 "Not Specified" among the 134 validation participants. The fourth study
file, `IDmapping_participantID_ImmPortSUBacc.txt`, links all 134 to their rows in the
current `Validation.zip`; 37 of the 38 belong to one of its two datasets. The earlier
`metadata.csv` agrees with the subject table on all 134 participants the two share; its 42
include four of the 14 participants the update removed. Training records no ethnicity in
any source.

Routes, in the order they are worth trying, and where each stands:

1. **Ask.** The paper names the lead contact (Marina Sirota) and MaLiAmPi's author
   (Jonathan Golob), and states that additional information needed to reanalyse the data
   is available from the lead contact on request. A reference package is a small file.
   **Asked on 2026-09-24**, by email to the authors: whether the reference package can be
   shared, and whether it is in fact what is needed to bring our samples into the
   Challenge's phylotype space. No reply as of 2026-10-12. **Reminder sent on 2026-10-15**,
   which also asks, as an alternative, for the sequences of the 2,358 validation variants:
   what Option B needs to reach the validation set (§3).
2. **Register** on Synapse / pretermbirthdb and look inside SDY2187 for it. **Checked**:
   the ImmPort metadata package and the data dictionary on 2026-09-24, `Training.zip` and
   both versions of `Validation.zip` on 2026-10-12 (table above). None of them contains it.
   That covers every file the SDY2187 download page offers.
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
[`NEXT_STAGE_MICHIGAN_COHORT.md` §3](NEXT_STAGE_MICHIGAN_COHORT.md).

## 4. Preconditions, in order

Each is a separate piece of work with its own product. Precondition 1 was settled on
2026-10-15; none of the others has been done.

| # | Task | Product that proves it is done |
|---|---|---|
| 1 | Decide between Option A and Option B (§3) and write the decision down, with the reason. **Decided on 2026-10-15 (§3): Option B is the main line; preconditions 2 to 7 are the Option A line.** | A dated paragraph in this document naming the chosen direction. Nothing else in this table should start before it. |
| 2 | Obtain the DREAM Challenge reference package. **Partly answered on 2026-09-24 — see §3b. It is not published anywhere we can find. The authors were asked for it by email on 2026-09-24; no reply as of 2026-10-12; reminder sent on 2026-10-15.** | The archive on disk, plus a row in this document giving origin, retrieval date, version or release tag, and SHA-256. If it turns out not to be distributable, that answer is recorded here instead — a documented dead end closes the objective just as well as a download. |
| 3 | Compare the two reference packages. | `Rscript scripts/describe_refpkg.R` run on both, outputs saved side by side under `metadata/`, and a short verdict: how many reference sequences each has, how much of the taxonomy they share, and whether re-placement is worth the compute. |
| 4 | Re-run placement and classification with the DREAM reference package, reusing the existing sequence variants. **The parameter question is answered — see §3c. The version we ran has no such parameter; current `master` has `--refpkg` but re-runs DADA2.** | A second output directory, its own manifest under `metadata/`, and a run record written the same way as [`RUN_MALIAMPI.md`](RUN_MALIAMPI.md). |
| 5 | Bin the placements into phylotypes at 0.1, 0.5 and 1.0 — using the same phylogenetic distance criterion the Challenge used, not our own. | Phylotype tables, their dimensions recorded, and the thresholds documented. |
| 6 | Assign VALENCIA community state types on the new species tables. | CST assignments, with the VALENCIA commit recorded ([`env/VERSIONS.md`](../env/VERSIONS.md)). CSTs were among the strongest features in the Challenge's winning models, so this is not optional decoration. |
| 7 | Check that our phylotype identifiers and the DREAM phylotype identifiers actually coincide. | An overlap report: how many phylotypes are shared, what fraction of each cohort's relative abundance falls in the shared set. This is the real gate — steps 4 to 6 can succeed mechanically and still leave the two cohorts in different spaces. |

### Questions to settle before estimating any timeline

None of these is resolved, and each can block the stage on its own.

| # | Question | How to answer it |
|---|---|---|
| 1 | ~~Is the DREAM reference package downloadable at all?~~ **Answered 2026-09-24: not from any published source (§3b).** The article publishes the MaLiAmPi code, not the package built with it. | The authors were asked by email on 2026-09-24; no reply as of 2026-10-12; reminder sent on 2026-10-15. The ImmPort SDY2187 metadata package and the data dictionary were checked the same day, and the study archives on 2026-10-12; none of them has it (§3b). |
| 2 | **What data use agreement does Synapse require?** | The Challenge data were aggregated from dbGaP and the March of Dimes database; part of it may need a formal access request with a turnaround of weeks to months. **This is the largest schedule risk in the whole stage, and it is administrative, not technical.** Start it before anything else. |
| 3 | Are the DREAM FASTQ files needed at all, or do their published feature tables suffice? | If the goal is comparing composition, or validating models, the published phylotype tables may be enough — which removes question 2 entirely. Option B needs the variants' sequences, not the raw reads (§3). Answering this first may dissolve the biggest risk. |
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
  stage now depends on the request made to the authors on 2026-09-24. If that fails, the fallback is to
  compare in a space that does transfer —
  species-level tables and VALENCIA community state types — and to say plainly that
  phylotype-level pooling was not possible. That comparison needs neither reference
  package and does not have to wait for the reply (§3).
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
| ImmPort SDY2187, its data dictionary and the study archives added to §3b; request to the authors and size of the Hispanic subgroup recorded | 2026-10-12 |
| Direction decided in §3: Option B the main line, Option A a separate line conditional on the authors' reply; reminder to the authors recorded | 2026-10-15 |
| The Challenge's winning models in §3: inputs, tree dependence, code, fitted models, licences, training data and validation scores under both rankings; Option A kept | 2026-10-21 |
| Status | not started; precondition 1 settled (§3); the Option A line is blocked on precondition 2 |
| Reviewed by | *pending* |
