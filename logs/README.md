# Logs

Excerpts kept as evidence. Everything asserted in `docs/` about *what was run* can be
traced to one of these files.

| File | What it is | Cut from |
|---|---|---|
| `maliampi_launch_command_final_2026-02-18.txt` | the `nextflow run` command line of the **final, successful** session, verbatim | first line of `~/datos_microbiota_vaginal/.nextflow.log` on the WSL machine, recovered 2026-09-24 |
| `maliampi_launch_command.txt` | the command line of the Nov-06 session, which failed; kept as evidence of that session | first line of the Nextflow debug log |
| `nextflow_runtime_header.txt` | engine version, workflow revision, session id, host and resources | Nextflow debug log |
| `maliampi_refpkg_build_processes.txt` | the twelve processes of the reference-package-building sub-workflow | final run trace |
| `maliampi_run_summary_2026-02-18.txt` | full process table and completion trailer of the final session | tail of `nohup.out` |

These are excerpts, not the full logs. The complete `.nextflow.log` (about 200 KB, one
line per task event) and the full `nohup.out` (about 80 KB of progress redraws) are
kept with the run outputs outside this repository; they add volume, not evidence.

The only edit made to any excerpt is in `maliampi_launch_command.txt`, where the
address passed to `--email` is replaced by `<redacted>`. Every other character is as
Nextflow wrote it.

## A note on dates

Nextflow does not stamp the year on its log timestamps. The debug log opens at
`Nov-06 14:49:04`; the file was captured on 2026-02-13, so that is 2025-11-06. The
final session completed at `18-Feb-2026 12:00:03`, which Nextflow does stamp in full.
