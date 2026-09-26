# Known issues

Open questions about this processing run, listed rather than smoothed over. Each one is
something a reader could otherwise trip on, or something that would have to be resolved
before the affected result is relied on.

Items are closed by editing this file and the document that carries the claim.

---

## 1. The exact command of the successful run has not been recovered

**Status:** resolved 2026-09-24.

`~/.nextflow/history` is empty on the WSL machine, which is why the earlier attempt
found nothing. The record is in the rotated logs of the run directory. The final
session (`serene_gautier`, 18-Feb-2026 11:54:13 → 12:00:03, "Execution complete") is
kept verbatim in
[`logs/maliampi_launch_command_final_2026-02-18.txt`](logs/maliampi_launch_command_final_2026-02-18.txt),
and quoted in [`docs/RUN_MALIAMPI.md` §3](docs/RUN_MALIAMPI.md). It differs from the
failed `Nov-06` session by one flag: `--cmalign_mxsize 4096`.

## 2. The `main.nf` patch is described in prose, not committed

**Status:** resolved 2026-09-24.

[`workflow/patches/main.nf.pplacer.patch`](workflow/patches/main.nf.pplacer.patch),
generated with `git diff main.nf` on the machine that holds the modified copy: 4 lines
added, 3 removed, exactly the change the prose described. It applies to
`github.com/jgolob/maliampi` at tag `v3.5.0`
(`333d83ba988157fcae07200dcdc861f6b3306938`) — the local directory is named
`maliampi_pplacer`, but there is no such upstream project.

## 3. `--cmalign_mxsize 4096` and the `AlignSV` CPU count are unverified

**Status:** resolved 2026-09-24, and they are set in two different places.

`--cmalign_mxsize 4096` is a command-line flag and is in the final session's invocation
(item 1). The CPU count is **not** a flag: `AlignSV` carries `label = 'mem_veryhigh'`,
which the `standard` profile caps at 1 CPU and 9 GB. The config now committed is the
copy that was in effect for the final session (item 12).

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

**Status:** resolved 2026-09-24 — there is one copy, and it was moved.

The run's `--output` was `~/datos_microbiota_vaginal/salida_analisis/`. **That directory
no longer exists.** The outputs are only at `~/archivos_extra/salida_analisis/`, and
their SHA-256 sums match
[`metadata/maliampi_outputs_manifest.csv`](metadata/maliampi_outputs_manifest.csv) file
for file (checked on `tallies_wide.genus.csv`, `tallies_wide.species.csv`,
`dada2.sv.fasta`, `refpkg.tar.gz` and `failed_specimens.csv`). So it was a move after
the run, not a second run, and nothing downstream consumed a different copy.

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

**Status:** resolved 2026-09-24.

All seventeen tags are now listed in [`env/VERSIONS.md`](env/VERSIONS.md), read off the
workflow source at the pinned commit. Two of them (`trim-galore`, `fastqc`) are declared
with single quotes in `modules/preprocess.nf`, so a grep written for double quotes
reports them as absent — which is how they came to be described as missing.

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

## 12. The committed `nextflow.config` now comes from the machine that ran

**Status:** resolved 2026-09-24, by replacing the file.

The copy of [`env/nextflow.config`](env/nextflow.config) previously committed came from an
**earlier snapshot** of the config: it capped `mem_veryhigh` at 6 CPUs and 11.5 GB. The
machine's `~/.nextflow/config` — last modified 2026-02-17, the day before the final
session, with no run ever passing `-c` — caps it at **1 CPU and 9 GB**. Three other
values differ as well, earlier snapshot versus machine: `multithread` CPUs (4 versus 2),
`io_mem` memory and the profile's default memory (11.5 GB versus 8 GB in both).

The difference matters for reproduction. `mem_veryhigh` is `AlignSV`'s label, and 6 CPUs
for `cmalign` is the configuration under which it exited with status 137, out of memory
(item 3). `workflow/run_maliampi.sh` passes this file with `-c`, so it now launches
`cmalign` with the caps the final session used, the ones reached after four rounds of
adjustment. The file is the verbatim machine copy, with the change described in its
header.

---

## Resolved

Items 1, 2, 3, 4, 5, 6, 8, 9 and 12 above are resolved and kept in place, so that
references to them by number stay valid. Items 7, 10 and 11 remain open.

**The WSL machine held the answers to five of them.** On 2026-09-24,
`\\wsl.localhost\Ubuntu-22.04\home\martinruhle` was inspected: the run directory, its
rotated Nextflow logs, the patched pipeline clone, the global Nextflow config and the
output copy. That closed items 1, 2, 3, 5 and 9, established that the workflow is
pinned by commit `333d83ba…` plus a patch rather than by the `3239c625a8` string the log
prints (see [`env/VERSIONS.md`](env/VERSIONS.md)), and led to item 12. The evidence is in
[`logs/`](logs/) and [`workflow/patches/`](workflow/patches/).

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

*Last updated 2026-09-26.*
