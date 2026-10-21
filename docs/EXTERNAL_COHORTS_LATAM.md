# Latin American and Hispanic vaginal microbiome datasets in pregnancy — what exists

**Purpose.** To decide which external data could extend the Mexican cohort documented in this
repository — 43 participants, 14 of them preterm, 16S V3–V4, processed with MaLiAmPi
([`RUN_MALIAMPI.md`](RUN_MALIAMPI.md)) — either as an external validation set or as extra
training data from a Mexican or Latin American context.

**Already identified elsewhere, not repeated here.** The Hispanic subgroup of the DREAM
Challenge validation set, 38 participants in ImmPort study SDY2187
([`NEXT_STAGE_DREAM_REFPKG.md` §1 and §3b](NEXT_STAGE_DREAM_REFPKG.md)), and the Michigan
cohort ([`NEXT_STAGE_MICHIGAN_COHORT.md`](NEXT_STAGE_MICHIGAN_COHORT.md)). Both are referenced
below only where a dataset here overlaps them.

**What was searched, and how.** Repository metadata was queried through the APIs rather than
through search pages, so the queries can be repeated: ENA's `country` field over every run with
a vaginal or cervical sample field, per Latin American country; NCBI BioProject and BioSample;
Europe PMC full texts for the Data Availability statement of every candidate article; Crossref
for the identity of every DOI. Literature was searched in English, Spanish and Portuguese.
One limitation is worth recording because it changes what a search means: **NCBI BioProject
free-text search by country is close to useless for this question** — a BioProject title rarely
names the country, and a text search for each of 21 Latin American countries combined with
vaginal and pregnancy terms returned exactly one project, our own `PRJNA1440471`. The country
lives in the **sample** records, which is why the ENA run-level sweep over `country` is the
query that found the rest.

**Scope.** Molecular profiling (16S of any region, shotgun metagenomics, or a targeted
PCR/qPCR panel) of vaginal or cervicovaginal samples from pregnant women, in Latin America or
in a Hispanic/Latina subgroup elsewhere. Studies based only on microscopy or culture (Nugent
score, Gram stain, wet mount) are recorded as dead ends in §5, because they cannot contribute
features to a model however large they are.

**Everything below was read on the page cited.** Where a number could not be confirmed on a
page, the cell says so. Nothing in this document is participant-level: counts only.

---

## 1. Verified datasets, ordered by what they would contribute to an external validation

The ordering criterion is the one the objective sets: per-participant birth outcome, plus
gestational age at sampling, plus obtainable sequence reads.

| # | Country / subgroup | Study | Accession | Access | Data type | Participants (samples) | Outcome per participant | Gestational age at sampling | Reads | Verdict |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | USA, Hispanic subgroup (Stanford + UAB) | Callahan 2017, *PNAS* ([10.1073/pnas.1705899114](https://doi.org/10.1073/pnas.1705899114)) | [`PRJNA393472`](https://www.ncbi.nlm.nih.gov/bioproject/PRJNA393472) (= `SRP115697`) | public, no application | 16S **V4**, Illumina | 136 with a subject id, of which **15 Hispanic**; 2,367 runs | **yes, public**: `term_vs_preterm_delivery` per sample → 6 preterm / 9 term among the 15 | **yes, public**: `gest_week_collection`, plus `gest_wk_delivery` | FASTQ | **usable for external validation** — the only accession found whose public sample metadata carries ethnicity, outcome, gestational age and maternal age together |
| 2 | USA, Hispanic subgroup (Stanford/UAB-enriched + MOMS-PI) | Berman 2024, *mSystems* ([10.1128/msystems.01339-23](https://doi.org/10.1128/msystems.01339-23)) | [`PRJNA1086504`](https://www.ncbi.nlm.nih.gov/bioproject/PRJNA1086504) | public, no application | **shotgun** metagenomics, HiSeq 4000 (human reads removed) | 35 subject ids, of which **10 Hispanic**; 107 samples | **yes, public**: `termpre` → 6 preterm / 4 term among the 10 | **yes, public**: `gdcoll` (collection), `gwdel` (delivery) | FASTQ (host-depleted) | **usable for external validation**, with the overlap caveat in §3 — its two enriched cohorts are the same Stanford and UAB cohorts as row 1 |
| 3 | Brazil (Porto Alegre) | Dobbler 2019, *World J Microbiol Biotechnol* ([10.1007/s11274-019-2737-3](https://doi.org/10.1007/s11274-019-2737-3)) and Roesch 2017, *PLOS ONE* ([10.1371/journal.pone.0169916](https://doi.org/10.1371/journal.pone.0169916)) | [`PRJNA354838`](https://www.ncbi.nlm.nih.gov/bioproject/PRJNA354838) (= `SRP093885`) | public, no application | 16S **V4**, Ion Torrent PGM | ~55 vaginal samples in two sets of 27: Roesch = women delivering **≤32 weeks**, Dobbler = women delivering **37–40 weeks** | **group level only** — the two sets are distinguishable by their sample accession ranges, but the deposited attributes are host, age, sex, isolation source, date and location, with no outcome field | at delivery, in both sets | FASTQ | **usable for external validation, with care** — the only Latin American accession found that holds both preterm and term vaginal samples from one laboratory and protocol; the outcome has to be carried in from the two articles |
| 4 | Puerto Rico (Hispanic) | Vargas-Robles 2023, *mSystems* ([10.1128/msystems.00357-23](https://doi.org/10.1128/msystems.00357-23)) | [`PRJEB51893`](https://www.ebi.ac.uk/ena/browser/view/PRJEB51893) (= `ERP136546`); also Qiita study 12871 | public, no application | 16S **V4**, MiSeq 2×250 | 294 women enrolled, of which **37 pregnant** (196 non-pregnant, 61 menopausal) | **no** — cross-sectional, HPV and cytology as outcomes | not stated for the pregnant subgroup | FASTQ | **characterization only** — a Hispanic pregnancy reference set with public reads and no birth outcome |
| 5 | Mexico (Mexico City) | González-Sánchez 2022, *Current Microbiology* ([10.1007/s00284-022-02918-1](https://doi.org/10.1007/s00284-022-02918-1)) | [`PRJNA746573`](https://www.ncbi.nlm.nih.gov/bioproject/PRJNA746573) | public, no application | 16S **V3**, Ion Torrent PGM | **10** women, 20 samples (third trimester and active childbirth) | **no** — the article states no preterm birth correlation was found | third trimester and labour | FASTQ | **characterization only** — too small for validation; useful as a second Mexican reference point |
| 6 | Chile (Santiago) and Bolivia | sample metadata only; project `MG_baby timeseries`, UCSD/NYU (Qiita 10894). The matching publication was not identified | [`PRJEB36857`](https://www.ebi.ac.uk/ena/browser/view/PRJEB36857) | public, no application | 16S, HiSeq 2500 | **418 vaginal samples** (Chile 329, Bolivia 89) across **26** mother subject ids | **no** — no outcome attribute; `mother_prenatal_gbs` and `mother_race` are `NA` in the record inspected | sampling is timed **relative to birth** (`Day_-1` … `Month_12`), so only a small prenatal fraction | FASTQ | **characterization only** — a mother–infant time series, not a pregnancy cohort; the largest Latin American vaginal read set found |
| 7 | USA, Hispanic subgroup (MOMS-PI, Virginia) | Fettweis 2019, *Nat Med* ([10.1038/s41591-019-0450-2](https://doi.org/10.1038/s41591-019-0450-2)); Serrano 2019, *Nat Med* ([10.1038/s41591-019-0465-8](https://doi.org/10.1038/s41591-019-0465-8)) | dbGaP `phs001523.v1.p1`; BioProjects `PRJNA326441`, `PRJNA326442`; an open subset at the HMP DACC | **controlled** — dbGaP application and Data Use Certification | 16S **V1–V3** | 45 preterm / 90 term, of which **8 Hispanic** (3 preterm, 5 term) by the article's Table 1 | yes, by design, in the controlled phenotype files | yes, in the controlled phenotype files | FASTQ behind the application | **characterization only until an application is granted** — and 8 participants would not carry a validation on their own |
| 8 | Brazil (São Paulo) | Amorim Filho 2025, *Diseases* ([10.3390/diseases13100338](https://doi.org/10.3390/diseases13100338)) | none; the Data Availability statement points to a Google Drive folder | public link, not a repository | 16S **V4** (515F/806R) | **44** women (22 per arm) of a 203-woman trial of pessary versus progesterone, 88 samples | not reported for the microbiome subset | **20–24 weeks**, and again 4 weeks later | not deposited in a repository | **characterization only** — all participants have a short cervix, so the sample is selected on a preterm risk factor; useful as a high-risk comparison, not as a validation set |

## 2. Probable, and what each one needs before it could be used

These are real datasets whose existence and design were confirmed on the article page, but
whose data are not deposited anywhere this search could find. Each one is a request away, and
three of them are better matched to our cohort than anything in §1.

| Country | Study | Design, as published | What it would contribute | What is missing |
|---|---|---|---|---|
| **Colombia** (Bucaramanga) | Becerra-Mojica 2022, *BMJ Open* ([10.1136/bmjopen-2021-060556](https://doi.org/10.1136/bmjopen-2021-060556)), the **COLPRET** cohort | first-trimester enrolment; **244** pregnant women, a vaginal microbiome sample in all 244; 16S/18S on Illumina MiSeq, primers directed to **V3 and V4**; outcome is spontaneous birth before 37 weeks; by August 2021, 100 had delivered and **11** were spontaneous preterm | the closest methodological match to our cohort that exists in Latin America: same region, same platform, same outcome, sampled earlier in pregnancy than ours | no accession. The Data Availability statement says the data are in the article or its supplements. The reads have to be requested |
| **Peru** (Lima) | Blostein 2020, *Ann Epidemiol* ([10.1016/j.annepidem.2019.11.004](https://doi.org/10.1016/j.annepidem.2019.11.004)) — the **PrOMIS** cohort | nested case–control inside a cohort of **785** women who gave vaginal swabs; **25** preterm against **100** term; 16S **V4** (515/806), denoised with **DADA2**; enrolment before 16 weeks, with analyses stratified at <12 weeks and 12–16 weeks | preterm outcome by design, early-pregnancy sampling, and the same denoiser as ours; the only Latin American preterm case–control with 16S found in this search | no accession found in the full text. The reads have to be requested |
| **Brazil** (São Paulo) | Witkin 2019, *mBio* ([10.1128/mbio.02242-19](https://doi.org/10.1128/mbio.02242-19)); same cohort in Witkin 2021 ([10.1007/s00404-021-05978-z](https://doi.org/10.1007/s00404-021-05978-z)), da Costa 2021 ([10.1111/1471-0528.16528](https://doi.org/10.1111/1471-0528.16528)) and Tozetto-Mendoza 2022 ([10.1371/journal.pone.0262672](https://doi.org/10.1371/journal.pone.0262672)) | mid-trimester cohort at three hospital clinics; 16S **V1–V3**; the mBio analysis uses 340 women for cervical length and reports a supplementary table of **629** women for the microbiome; mean gestational age at sampling **21.5 weeks**, mean maternal age 29.1 years; **preterm birth in 16.5 % of the 261** women with a delivery outcome | by far the largest Latin American pregnancy vaginal microbiome cohort found, with outcome, gestational age and maternal age | no accession in any of the four articles. Note that in the 494-woman companion study the women at risk were given progesterone after sampling, which the authors say prevented them from analysing the outcome |
| **Guatemala** (Guatemala City) | Rick 2017, *Open Forum Infect Dis* ([10.1093/ofid/ofx020](https://doi.org/10.1093/ofid/ofx020)) | cross-sectional study at a public hospital, women **≥35 weeks**; 1,100 enrolled, 896 analysed for group B *Streptococcus*; vaginal microbiome by 16S **V3–V4** (357F/806R) on MiSeq in a subset of **94** women | the only Central American 16S pregnancy dataset found, and in our own variable region | no accession. Sampling is late (≥35 weeks) and the design is a colonisation study, so preterm birth appears only as a risk criterion, not as a cohort outcome |
| **Mexico** (Tabasco) | García-Avalos 2025, *Diseases* ([10.3390/diseases13110375](https://doi.org/10.3390/diseases13110375)) | a causal model fitted to a third-party dataset of **132** pregnant women, 4–24 weeks, one sample each, with species-level variables (*Mycoplasma hominis*, *Atopobium vaginae*, BVAB2, *Lactobacillus crispatus*), i.e. a targeted molecular panel rather than microscopy | a second Mexican dataset with gestational age at sampling | the authors did not generate the data; the statement says they are available from the corresponding author on request. No birth outcome is reported, and a targeted panel cannot be placed on a reference tree |

## 3. Overlap, and why it matters here

Rows 1, 2 and 7 of §1 are not independent of each other, nor of work already in this project's
plans, and pooling them would count the same women more than once.

- **Rows 1 and 2 share cohorts.** The shotgun study's two enriched cohorts are the Stanford and
  UAB cohorts of Callahan 2017, and its third is MOMS-PI, which is row 7. Its 10 Hispanic
  participants are therefore likely to be a subset of row 1's 15 plus row 7's 8, not 10 more.
  How many distinct women the three rows hold has not been established and cannot be
  established from public metadata alone.
- **All three are DREAM source studies.** Callahan 2017 is the Challenge's study G, MOMS-PI its
  study H ([`NEXT_STAGE_DREAM_REFPKG.md` §3b](NEXT_STAGE_DREAM_REFPKG.md)). Any of them used as
  an external validation set for a model trained on DREAM data would not be external.
- **Row 1 is where the Challenge's own ethnicity information went missing.** The Challenge's
  harmonized training metadata records no ethnicity, and its validation metadata is the 38-participant
  Hispanic subgroup already documented. Row 1 recovers, from the public sample records of one
  source study, the per-participant Hispanic status that the harmonized tables dropped.

## 4. What the DREAM Challenge article itself reports by ethnicity

Checked because the objective asks: **the Challenge does not report model performance separated
by ethnicity.** Golob 2024, *Cell Rep Med* ([10.1016/j.xcrm.2023.101350](https://doi.org/10.1016/j.xcrm.2023.101350))
and the whole of its Document S1 (Figures S1–S11, Tables S1–S5, S8) carry no AUROC or AUPRC
separated by race or ethnicity. Ethnicity appears twice: as demographics in Table 1, and
descriptively in Supplementary Figure 3, which colours a UMAP of samples by race and ethnicity.
Race does enter several teams' models as an input feature. A citation search over the papers
citing the Challenge found no follow-up that reports performance by ethnicity either.

Two further points from the same check:

- A **2025 notice published alongside the article** ([10.1016/j.xcrm.2025.102428](https://doi.org/10.1016/j.xcrm.2025.102428))
  removes 12 individuals who appeared in both the training and the validation data, reducing
  validation study S from 86 to 74 participants, and updates Tables 1, 2 and S1–S5. The
  updated Table 1 itself could not be retrieved, so the ethnicity counts quoted in
  [`NEXT_STAGE_DREAM_REFPKG.md` §3b](NEXT_STAGE_DREAM_REFPKG.md) should be re-checked against it
  before they are used in a manuscript.
- Of the Challenge's nine training studies, **only Callahan 2017 exposes ethnicity per
  participant publicly** (§1 row 1). The others record race without a Hispanic category
  (Romero 2014, `PRJNA242473`), race only in the article (Elovitz 2019, `PRJNA504518` /
  `phs001739.v1.p1`, framed as African American versus not), nothing at all (Stout 2017,
  `PRJNA294119`), or UK ethnicity categories (the four Imperial College studies `PRJEB11895`,
  `PRJEB12577`, `PRJEB21325`, `PRJEB30642`).

## 5. Dead ends, and why each is one

Recorded so the same ground is not searched twice.

**US cohorts with a Hispanic subgroup too small to validate anything.** The **ECHO** consortium
(McKee 2024, [10.1038/s41598-024-62537-7](https://doi.org/10.1038/s41598-024-62537-7); McKee 2025,
[10.1016/j.annepidem.2025.11.003](https://doi.org/10.1016/j.annepidem.2025.11.003);
`PRJNA725416`, `PRJNA1041860`, `PRJEB46659`) has **13 Hispanic participants of about 678**, 1 of
them preterm, and harmonized race to Black versus non-Black; the deposited attributes of
`PRJNA1041860` carry no ethnicity at all. The **Wayne State** longitudinal cohort (Romero 2023,
[10.1128/spectrum.03429-22](https://doi.org/10.1128/spectrum.03429-22), `PRJNA895490`) is 94.5 %
African American with **1 Hispanic participant of 474**. The **Idaho** cohort (Nunn 2021,
[10.1007/s43032-020-00438-6](https://doi.org/10.1007/s43032-020-00438-6), `PRJNA614593`) reports
4.2 % Hispanic of 48 women, all term. The **UNC PIN** study (Sun 2022,
[10.1128/msystems.00017-22](https://doi.org/10.1128/msystems.00017-22), `PRJNA694098`) frames
race as Black versus White and its 824 deposited samples carry no race or ethnicity field. The
**Hawai'i** multi-ethnic diet study ([10.3390/nu16193405](https://doi.org/10.3390/nu16193405))
has 40 participants in four groups, none of them Hispanic.

**Latin American accessions that are not pregnancy.** Mexican cervicovaginal work is plentiful
and almost all of it is about HPV or candidiasis in non-pregnant women: `PRJNA766648`,
`PRJNA763215`, `PRJNA814210`, `PRJNA1479850`, `PRJNA1199545`, `PRJNA684969`. Puerto Rico's
`PRJNA429969` is HPV. Peru's `PRJNA1077994` (Lima, cervicovaginal microbiome and virome in
discordant HIV shedding) and `PRJNA1114400` (a vaginal ring trial in women with HIV, Rio de
Janeiro, Lima and Chicago) are not pregnancy cohorts. Venezuela's `PRJEB14801` holds 5 vaginal
samples from Alto Orinoco in a study of urbanisation, not pregnancy. Colombia's `PRJNA1356845`
is recurrent vulvovaginal candidiasis; Chile's `PRJNA1232418` and `PRJNA1215533` are
self-sampling and sexually transmitted infection studies in non-pregnant women; Brazil's
`PRJNA1229766` is climacteric women. Haiti's `PRJNA305167` (50 vaginal samples, Port-au-Prince,
mother–infant pairs in HIV infection) is **not verified** either way: the samples are maternal
and vaginal, but whether any was taken during pregnancy was not established.

**Latin American pregnancy studies with no molecular data to contribute.** Mexico:
Hernández-Rodríguez 2011 ([10.1155/2011/851485](https://doi.org/10.1155/2011/851485)) profiled
64 pregnant women in Mexico City by PCR-DGGE with Sanger sequencing of excised bands — 21
species identified, no read set; Olamendi-Portugal 2025, *Salud Pública de México*
([10.21149/16730](https://doi.org/10.21149/16730)) followed **501** pregnant adolescents by Gram
stain and Nugent score, a large and well-designed study with nothing sequenceable in it.
Ecuador: Salinas 2018 ([10.7717/peerj.4317](https://doi.org/10.7717/peerj.4317)) tested 95
pregnant teenagers in Quito at 10–13 weeks by species-specific PCR for 8 organisms, all
participants Hispanic, and states that no correlation with preterm birth could be assessed;
Pacha-Herrera 2020 ([10.3389/fcimb.2020.00303](https://doi.org/10.3389/fcimb.2020.00303))
quantified lactobacilli by qPCR in 217 women, 111 of them pregnant, with no outcome. Argentina:
Galiñanes 2011 ([10.5402/2011/835926](https://doi.org/10.5402/2011/835926)) examined 1,248
vaginal exudates across the three trimesters in Buenos Aires by microscopy and culture. Chile:
Palma 2019 ([10.4067/s0716-10182019000300292](https://doi.org/10.4067/s0716-10182019000300292))
screened 85 pregnant women by PCR for three pathogens with microscopy for the microbiota.
Colombia: Montenegro 2019 ([10.1111/jicd.12396](https://doi.org/10.1111/jicd.12396)) used nested
PCR for 27 organisms on placental tissue, not vaginal samples, in 84 preterm and 127 term
deliveries in Bogotá. Panama: González-Fernández 2015
([10.4269/ajtmh.14-0547](https://doi.org/10.4269/ajtmh.14-0547)) surveyed 213 pregnant Ngäbe
women by microscopy and culture.

## 6. Conclusions

1. **Fewer than three new, independent datasets are usable for external validation today.**
   Three accessions carry a Hispanic subgroup with per-participant outcome and gestational age
   (§1 rows 1, 2, 7), but they overlap each other, all three are DREAM source studies, and the
   largest Hispanic subgroup among them is 15 participants with 6 preterm.
2. **The one new thing worth taking now is `PRJNA393472`.** It is public, it needs no
   application, and its sample records hold ethnicity, term versus preterm delivery,
   gestational week at collection and at delivery, and maternal age together. It is 16S V4, so
   it reaches our feature space through the reference package, not through sequence variants.
3. **Latin America's own public data cannot validate a preterm model.** The region's public
   vaginal read sets are either not pregnancy (§5), or pregnancy without birth outcome (§1 rows
   4, 5, 6), with the single exception of the Porto Alegre pair (§1 row 3), whose outcome is a
   group label from two articles rather than a field in the deposited metadata.
4. **The data that would matter most are published but not deposited.** COLPRET in Colombia
   (244 women, V3–V4 MiSeq, spontaneous preterm outcome, first-trimester sampling) and PrOMIS in
   Peru (125 women, 25 of them preterm, V4, DADA2, sampling before 16 weeks) are each a single
   request away and each is a closer match to our cohort than anything that is public. The São
   Paulo cohort of Witkin and colleagues is the largest of all, at about 629 women with
   V1–V3 and a 16.5 % preterm rate among those with an outcome.
5. **So the next step is four requests, not a download.** To Becerra-Mojica and colleagues at
   the Universidad Industrial de Santander for COLPRET; to Foxman and colleagues at the
   University of Michigan, with the Universidad de San Martín de Porres, for PrOMIS; to Witkin
   and colleagues at Weill Cornell and their São Paulo collaborators; and to Rick and
   colleagues for the 94 Guatemalan V3–V4 samples. Each request should ask for the raw reads
   and for outcome, gestational age at sampling and maternal age per participant — the three
   variables of the minimal adjustment used in the
   [analysis compendium](https://github.com/martinruhle/Mexican-PretermBirth-analysis#clinical-variable-sets).
6. **The combination that would give the most participants with an outcome** is COLPRET (244,
   11 preterm among the first 100 delivered) plus PrOMIS (125, 25 preterm) plus São Paulo (261
   with an outcome, about 43 preterm), all Latin American, all granted by request — roughly 630
   participants against the 15-participant Hispanic subgroup that is public today. If none of
   the four requests is answered, the realistic position is the one stated in conclusion 1, and
   the external validation rests on the DREAM Hispanic subgroup and the Michigan cohort already
   documented.
7. **One thing to settle before any of these data is used.** Three variable regions appear
   across the candidates — V4 in rows 1 to 6, V1–V3 in row 7 and in São Paulo, V3–V4 in COLPRET
   and Guatemala. Taxonomic names transfer across regions and phylotypes do not
   ([`NEXT_STAGE_DREAM_REFPKG.md` §1](NEXT_STAGE_DREAM_REFPKG.md)), so a validation that is to
   run at phylotype level has to place every incoming read set on our reference package, as
   planned for the Michigan cohort, and the coverage of that placement has to be measured per
   dataset before any result from it is believed.

---

| | |
|---|---|
| Written | 2026-10-21 |
| Sources | repository metadata through the ENA, NCBI and Europe PMC APIs; article pages as cited. Every number in §1 to §5 was read on the page or API response linked beside it |
| Status | inventory; no data obtained and none downloaded |
| Reviewed by | *pending* |
