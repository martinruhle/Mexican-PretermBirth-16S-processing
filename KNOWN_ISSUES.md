# Known issues

Open questions about this processing run, listed rather than smoothed over. Each one is
something a reader could otherwise trip on, or something that would have to be resolved
before the affected result is relied on.

Items are closed by editing this file and the document that carries the claim.

---

## 1. The exact command of the successful run has not been recovered

**Status:** open. **Blocks:** exact reproduction of the run.

The only Nextflow log kept in the project is from the `Nov-06` session
(`jovial_mercator`), which **failed** at `make_refpkg_wf:TaxtableForSI`. The final
successful run additionally passed `--cmalign_mxsize 4096` and a reduced CPU count for
`AlignSV`, but that command line is not in any file we hold.

To close it, on the WSL machine:

```bash
cd ~/datos_microbiota_vaginal
cat .nextflow/history      # one line per run, with the full command
ls -lt .nextflow.log*
```

Then replace the command in [`docs/RUN_MALIAMPI.md`](docs/RUN_MALIAMPI.md) and in
[`workflow/run_maliampi.sh`](workflow/run_maliampi.sh), and drop the warning boxes.

## 2. The `main.nf` patch is described in prose, not committed

**Status:** open. **Blocks:** running the pipeline from a clean checkout.

The run used a locally modified `main.nf` (EPA-NG placement swapped for pplacer). The
change is written out in [`docs/RUN_MALIAMPI.md` §4](docs/RUN_MALIAMPI.md), but the patch
file itself lives only on the WSL machine. Generate it with `git diff main.nf` in
`~/.nextflow/assets/jgolob/maliampi_pplacer` and commit it under `workflow/patches/`.

## 3. `--cmalign_mxsize 4096` and the `AlignSV` CPU count are unverified

**Status:** open. **Blocks:** nothing today; matters when the run is repeated.

Both values come from the project's working history, not from a log. Confirm against
`.nextflow/history` (see item 1). Recorded in
[`docs/TROUBLESHOOTING.md` §4](docs/TROUBLESHOOTING.md) with the same caveat.

## 4. `Au122_S43` versus `Au122_S41`

**Status:** resolved 2026-09-21 — `Au122_S43` is correct, and no file we hold says S41.

This item recorded that `tallies_wide.species.csv` reports `Au122_S41`. It does not. Both
copies of that file (SHA-256 `61c030dc…`, the one in the manifest) say `Au122_S43`. So do
`tallies_wide.genus.csv`, the 1,415 rows of `dada2.specimen.sv.long.csv`, the FASTQ file
names and the MaLiAmPi input manifest. The sequencer's QC report puts Au122 at position
43 of the sample sheet. A search of the project data folder and of the analysis
compendium finds `Au122_S41` nowhere. Joins go through the Au number alone (item 8), so
the suffix does not enter any join.

## 5. Where the `classify/` tables actually live

**Status:** open. **Blocks:** nothing; it is a provenance ambiguity.

The run's `--output` was `~/datos_microbiota_vaginal/salida_analisis/`, but the tables
used downstream were taken from a copy under `archivos_extra/salida_analisis/`. Whether
that is a manual copy, or the output of a second run, has not been established. The
checksums in
[`metadata/maliampi_outputs_manifest.csv`](metadata/maliampi_outputs_manifest.csv) were
computed on the `archivos_extra` copy — which is the copy every number in this repository
describes. To close:

```bash
md5sum ~/datos_microbiota_vaginal/salida_analisis/classify/tables/tallies_wide.species.csv
md5sum ~/archivos_extra/salida_analisis/classify/tables/tallies_wide.species.csv
```

## 6. 111 specimens here, 110 in the analysis matrix

**Status:** resolved 2026-09-21.

The MaLiAmPi tables carry 111 specimen columns; the genus matrix used in
[`Mexican-PretermBirth-analysis`](https://github.com/martinruhle/Mexican-PretermBirth-analysis)
has 110 rows. The missing specimen is **Au297**. It has 328 QIIME2 counts, below the
1,000-count filter of `convert_to_relative_abundance.R`. The canonical specimen map records
it as `en_analisis = no` with that reason
([`docs/CONCORDANCE_QIIME2_MALIAMPI.md` §6](docs/CONCORDANCE_QIIME2_MALIAMPI.md)). MaLiAmPi
itself dropped nothing (`failed_specimens.csv` is empty).

## 7. The QIIME2 side of the input chain is undocumented

**Status:** open. **Blocks:** reproducing the concordance analysis from scratch.

The May concordance run consumed `genus_rel_filtered_conc_2026-03-06_abs.csv`, which is
**not** the matrix behind the published manuscript
(`genus_rel_filtered_2025-05-25_abs.csv`). The steps separating them live in loose `.Rmd`
files outside any repository.

**Narrowed 2026-09-21.** For the concordance this no longer matters. That file's counts
are, row for row, the raw QIIME2 export's counts (`level-6_vag138.xlsx`), and no decontam
or filtering touched them. In four rows (labels Au52, Au197, Au179, Au203) the counts are
those of the other member of a pair. The re-run reads the raw export directly, keyed by
the canonical map, which anchors every row to its own specimen
([`docs/CONCORDANCE_QIIME2_MALIAMPI.md` §4–§5](docs/CONCORDANCE_QIIME2_MALIAMPI.md)). What
is still undocumented is how the analysis compendium's matrices were derived from that
export, and that belongs to the compendium.

## 8. Sample ID formats have not been checked end to end

**Status:** resolved 2026-09-21 for the MaLiAmPi ↔ QIIME2 ↔ canonical map join.

On 2026-09-21 the identifiers were checked against each other for all 111 specimens:
- The MaLiAmPi `_S##` suffix equals the sample-sheet position in the sequencer's QC
  report (111 / 111).
- The Au numbers are the same set in MaLiAmPi, in the raw QIIME2 export and in the
  canonical map.
- MaLiAmPi read totals track the sequencer's per-specimen read counts (Spearman 0.914)
  and the QIIME2 counts of the same Au (0.947).

The join key is the Au number. MaLiAmPi's `_S##` suffix is dropped before joining. The
evidence is [`analysis/as_run/verify_sample_pairing_2026-09-21.R`](analysis/as_run/verify_sample_pairing_2026-09-21.R)
and its log. The Au → participant step is not re-derived here: it is the canonical map's,
and that map is the only source used.

## 9. Container tags are only partially recorded

**Status:** open. **Blocks:** full version pinning.

Only `golob/taxtastic:0.9.5D` appears in the surviving log. The tags for DADA2, pplacer,
barcodecop, TrimGalore and FastQC are pinned by workflow revision `3239c625a8` but have
not been written down. See [`env/VERSIONS.md`](env/VERSIONS.md).

## 10. `metadata_qiime.csv` must not be used, and the QIIME2 pipeline still points to it

**Status:** open. **Blocks:** any re-run of the QIIME2 pipeline as currently configured.

`Datos_mexicanos/metadata_qiime.csv` (SHA-256 `3c0b8761…`, dated 2025-10-16) was
assembled by hand. Against the canonical map, it attaches a different (participant,
visit) to **30 of the 110** analysed specimens: 12 to another participant, and 18 to
another visit of the same participant. It flips the preterm outcome of **8** of them (10
if Term ↔ Postterm is counted). It also carries Au297, which the map excludes. (Its
`index_num` numbers specimens 1–111, not the analysis `index`, so it cannot be compared
on that column at all.)

The QIIME2 pipeline script, `Datos_mexicanos/QIIME2/qiime2_pipeline.sh` (outside this
repository), still reads it at lines 15 and 54–56. The QIIME2 feature counts themselves
are keyed by sample ID and are not affected. Anything that merges this file in is
affected: taxa-barplot exports with metadata columns, grouped diversity tests, any
visualization split by outcome.

Nothing in this repository uses it. The linkage comes only from the canonical map
([`docs/CONCORDANCE_QIIME2_MALIAMPI.md` §6](docs/CONCORDANCE_QIIME2_MALIAMPI.md)). To
close: point the pipeline at a metadata file generated from the canonical map, or retire
the script. Then record which QIIME2 outputs, if any, were produced with this file.

## 11. The library-concentration column in `genus_rel_filtered_conc_2026-03-06_abs.csv` follows a different row order

**Status:** open. **Blocks:** any decontam (frequency method) run from that file.

That file carries a column `[BIB](ng/ul)1`. Its 110 values are all real concentrations
from the library QC report, but only **3** coincide with the canonical value for the
specimen in their row (Spearman against the canonical value: 0.002, so effectively a
random permutation). The concordance does not read this column. A contaminant
identification that takes it as DNA concentration pairs most specimens with another
specimen's concentration. The canonical map's `conc_biblioteca_ng_ul` is the verified
value per Au.

---

## Resolved

Items 4, 6 and 8 above are resolved and kept in place, so that
references to them by number stay valid.

**Four specimens re-anchored in the concordance.** In the QIIME2 input of the May run, the
rows labelled Au52 and Au197 held each other's counts, and so did the rows labelled Au179
and Au203. On 2026-09-21 every row was anchored to its own specimen's counts through the
canonical specimen map. The re-run raises every paired statistic (median Spearman ρ 0.529
→ 0.585, Mantel 0.940 → 0.958, Procrustes 0.917 → 0.925) and leaves the verdict unchanged.
See [`docs/CONCORDANCE_QIIME2_MALIAMPI.md` §4](docs/CONCORDANCE_QIIME2_MALIAMPI.md).

**177,503 counts specimen–variant pairs, not variants.** Earlier project material quoted
177,503 as a count of sequence variants. It is the number of specimen–variant *pairs* with
a non-zero count in the long-format table. The number of distinct sequence variants is **21,382**.
Both were re-derived from `sv/dada2.specimen.sv.long.csv` on 2026-08-30 (177,503 rows,
21,382 distinct `sv` values, 111 distinct specimens, 28,277,142 total reads) and this
repository uses 21,382 throughout.

Searched for the earlier figure: `Mexican-PretermBirth-analysis` (no matches) and the
text of the fourth tutorial presentation (no matches — it quotes neither number). The
only hits anywhere were coincidental digit runs inside binary and data files. Nothing
found needs updating, but the manuscript PDF was not searched.

---

*Last updated 2026-09-21.*
