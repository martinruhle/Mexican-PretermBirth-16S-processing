# Metadata

Small files that identify the large ones. None of them contains sequence or abundance
data; all of them are regenerable by the scripts named below.

| File | What it is | Regenerate with |
|---|---|---|
| `maliampi_outputs_manifest.csv` | every file the MaLiAmPi run produced, with size and SHA-256 (41 files, ~1.3 GB of data described in 4 KB); then the files every join to the cohort depends on (rows under `metadata/`) | `MALIAMPI_OUT=<dir> bash scripts/make_output_manifest.sh` |
| `refpkg_CONTENTS.json` | the taxtastic manifest of the reference package: build date, file roles, per-file MD5 sums, and the build log | copied from inside `refpkg.tar.gz` |
| `refpkg_RAxML_info.txt` | RAxML run information for the reference phylogeny: version, model, command line, likelihoods | copied from inside `refpkg.tar.gz` |
| `refpkg_description.txt` | the summary numbers quoted in `docs/REFPKG_PROVENANCE.md` | `Rscript scripts/describe_refpkg.R <refpkg.tar.gz>` |

## The canonical specimen map: listed, not included

`mapa_muestras_2026-09-20.csv` is the only source of the link from specimen (`Au###`) to
participant, visit and outcome
([`docs/CONCORDANCE_QIIME2_MALIAMPI.md` §6](../docs/CONCORDANCE_QIIME2_MALIAMPI.md)). It
is clinical metadata, so the local copy in this directory is **git-ignored**, and only its
last manifest row is versioned:

```
metadata/mapa_muestras_2026-09-20.csv,7902,3b7e0b31ce6a8634c5951eeac4cf8223adfc8c3bfe00efc51293c272d5df4c91
```

Rows whose path starts with `metadata/` are relative to the repository root, not to
`MALIAMPI_OUT`. If the map is present, `make_output_manifest.sh` re-hashes it. If it is
absent, the recorded row is carried over with a warning, so regenerating the manifest
without the map does not silently drop it.

## Why manifests instead of data

Two people can confirm they are working from the same tables by comparing a 4 KB CSV,
without either of them moving 1.3 GB or publishing participant-level counts. If a
downstream result ever fails to reproduce, the first question — *are we even holding
the same input?* — is answerable in one command:

```bash
MALIAMPI_OUT=/path/to/salida_analisis bash scripts/make_output_manifest.sh
git diff metadata/maliampi_outputs_manifest.csv
```

An empty diff means the inputs are identical. A non-empty one names the file that
changed.
