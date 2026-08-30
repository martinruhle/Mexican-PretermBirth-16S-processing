#!/usr/bin/env Rscript
# ---------------------------------------------------------------------------
# Describe a taxtastic reference package (refpkg.tar.gz).
#
# Prints the SHA-256 of the archive plus the summary numbers quoted in
# docs/REFPKG_PROVENANCE.md, so that document can be re-checked rather than
# taken on trust. It works on any refpkg, so it is also the tool for comparing
# ours against the DREAM Challenge one (docs/NEXT_STAGE_DREAM_REFPKG.md).
#
# Usage:
#   Rscript scripts/describe_refpkg.R /path/to/refpkg.tar.gz
#
# Base R only; 'digest' is used for the SHA-256 if it happens to be installed.
# ---------------------------------------------------------------------------

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) {
  stop("usage: Rscript scripts/describe_refpkg.R <refpkg.tar.gz>", call. = FALSE)
}
archive <- normalizePath(args[[1]], mustWork = TRUE)

tmp <- file.path(tempdir(), paste0("refpkg_", as.integer(Sys.time())))
dir.create(tmp, recursive = TRUE)
on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
utils::untar(archive, exdir = tmp)

nl  <- "
"
say <- function(...) cat(..., nl, sep = "")
kv  <- function(k, v) cat(sprintf("%-28s %s", paste0(k, ":"), v), nl, sep = "")

# Pull the value out of a one-line JSON entry such as
#   "create_date": "2026-02-18 01:11:21",
# without regex escapes (this file is edited through tooling that collapses
# doubled backslashes, so patterns here stay backslash-free on purpose).
json_value <- function(line) {
  if (is.na(line)) return(NA_character_)
  gsub('[",]', "", trimws(sub(".*: ", "", line)))
}

say("== Archive ==")
kv("file", basename(archive))
kv("bytes", format(file.info(archive)$size, big.mark = ","))
kv("sha256", if (requireNamespace("digest", quietly = TRUE)) {
  digest::digest(archive, algo = "sha256", file = TRUE)
} else {
  "package 'digest' not installed; run sha256sum on the file instead"
})

contents <- file.path(tmp, "CONTENTS.json")
if (file.exists(contents)) {
  txt <- readLines(contents, warn = FALSE)
  say("")
  say("== CONTENTS.json ==")
  kv("create_date", json_value(grep("create_date", txt, value = TRUE)[1]))
  kv("format_version", json_value(grep("format_version", txt, value = TRUE)[1]))
  kv("locus", json_value(grep("locus", txt, value = TRUE)[1]))
}

aln <- file.path(tmp, "recruits.aln.fasta")
if (file.exists(aln)) {
  n_seq <- sum(startsWith(readLines(aln, warn = FALSE), ">"))
  say("")
  say("== Reference sequences ==")
  kv("aligned sequences", format(n_seq, big.mark = ","))
}

si_path <- file.path(tmp, "references_seq_info.csv")
if (file.exists(si_path)) {
  si <- utils::read.csv(si_path, stringsAsFactors = FALSE)
  kv("seq_info rows", format(nrow(si), big.mark = ","))
  kv("length (bp)", sprintf("%d - %d (median %d)",
                            min(si$length), max(si$length),
                            as.integer(stats::median(si$length))))
  kv("distinct species_name", format(length(unique(si$species_name)), big.mark = ","))
  kv("distinct genus_name",   format(length(unique(si$genus_name)),   big.mark = ","))
  kv("download_date range", sprintf("%s .. %s",
                                    min(si$download_date, na.rm = TRUE),
                                    max(si$download_date, na.rm = TRUE)))
}

tt_path <- file.path(tmp, "refpkg.taxtable.csv")
if (file.exists(tt_path)) {
  tt <- utils::read.csv(tt_path, stringsAsFactors = FALSE)
  say("")
  say("== Taxonomy table ==")
  kv("nodes", format(nrow(tt), big.mark = ","))
  for (r in c("species", "genus", "family", "order", "class", "phylum")) {
    kv(paste0("rank = ", r), format(sum(tt$rank == r), big.mark = ","))
  }
}

info <- file.path(tmp, "RAxML_info.refpkg")
if (file.exists(info)) {
  txt <- readLines(info, warn = FALSE)
  say("")
  say("== Tree inference ==")
  kv("RAxML", trimws(grep("^This is RAxML version", txt, value = TRUE)[1]))
  kv("alignment patterns", trimws(grep("distinct alignment patterns", txt, value = TRUE)[1]))
  kv("gaps/undetermined",  trimws(grep("Proportion of gaps", txt, value = TRUE)[1]))
}
