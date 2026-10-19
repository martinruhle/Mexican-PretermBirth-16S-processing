#!/usr/bin/env Rscript
# ---------------------------------------------------------------------------
# Check what MaLiAmPi's classify/tables/*.csv contain.
#
# For each rank (phylum, class, order, family, genus, species) it rebuilds the
# taxon x specimen matrix from two upstream files and compares it with
# tallies_wide.<rank>.csv cell by cell:
#
#   sv/dada2.specimen.sv.long.csv   DADA2 read count of each SV in each specimen
#   classify/sv_taxonomy.csv        the label of each SV at each want_rank
#
#   expected[label, specimen] = sum of DADA2 counts of the SVs carrying that
#                               label at that want_rank
#
# It then checks by_specimen.<rank>.csv and by_taxon.<rank>.csv against the
# same rebuilt matrix (see the "by_specimen" and "by_taxon" blocks below for
# the column definitions being tested).
#
# The inputs are hashed and compared with metadata/maliampi_outputs_manifest.csv
# first, so the log says which files it describes. The log carries only counts,
# sums over the whole run and Au### specimen IDs: no per-specimen abundance.
#
# Usage:
#   Rscript scripts/check_tallies.R <salida_analisis directory> > results/tallies_check/check_tallies.log
#
# Needs readr (quoted fields: compound tax_id such as "1678,848") and digest.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(readr)
  library(digest)
})

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) {
  stop("usage: Rscript scripts/check_tallies.R <salida_analisis directory>", call. = FALSE)
}
base <- normalizePath(args[[1]], winslash = "/", mustWork = TRUE)

# The manifest sits next to this script's repository root.
script_path <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
repo <- normalizePath(file.path(dirname(script_path), ".."), winslash = "/")
manifest <- read_csv(file.path(repo, "metadata", "maliampi_outputs_manifest.csv"),
                     col_types = cols(.default = col_character()))

ranks <- c("phylum", "class", "order", "family", "genus", "species")
say <- function(...) cat(..., "\n", sep = "")
fmt <- function(x) format(x, big.mark = ",", scientific = FALSE, trim = TRUE)
read_chr <- function(path) {
  read_csv(path, col_types = cols(.default = col_character()),
           na = character(), name_repair = "minimal", progress = FALSE)
}
n_fail <- 0L
check <- function(label, ok) {
  ok <- isTRUE(ok)  # an NA anywhere counts as a failure
  if (!ok) n_fail <<- n_fail + 1L
  say(sprintf("  %-58s %s", label, if (ok) "OK" else "FAIL"))
}

say("check_tallies.R")
say("R ", as.character(getRversion()), ", readr ", as.character(packageVersion("readr")))
say("")

# --- 1. Inputs are the ones in the manifest --------------------------------
say("1. Inputs against metadata/maliampi_outputs_manifest.csv")
inputs <- c("sv/dada2.specimen.sv.long.csv", "classify/sv_taxonomy.csv",
            sprintf("classify/tables/%s.%s.csv",
                    rep(c("tallies_wide", "by_specimen", "by_taxon"), each = length(ranks)),
                    ranks))
for (f in inputs) {
  sha <- digest(file.path(base, f), algo = "sha256", file = TRUE)
  want <- unique(manifest$sha256[manifest$relative_path == f])
  check(sprintf("%s %s", substr(sha, 1, 6), f), length(want) == 1L && identical(sha, want))
}
say("")

# --- 2. DADA2 counts -------------------------------------------------------
long <- read_csv(file.path(base, "sv/dada2.specimen.sv.long.csv"),
                 col_types = cols(specimen = "c", sv = "c", count = "c"), progress = FALSE)
say("2. DADA2 long table")
check("every count is a non-negative integer", all(grepl("^[0-9]+$", long$count)))
long$count <- as.numeric(long$count)
check("no duplicated (specimen, sv) pair", !anyDuplicated(long[c("specimen", "sv")]))
dada2_tot <- tapply(long$count, long$specimen, sum)
specimens <- sort(names(dada2_tot))
say("  rows: ", fmt(nrow(long)), "; distinct SVs: ", fmt(length(unique(long$sv))),
    "; specimens: ", length(specimens), "; reads: ", fmt(sum(long$count)))
say("")

tax <- read_csv(file.path(base, "classify/sv_taxonomy.csv"),
                col_types = cols(.default = "c"), progress = FALSE)

# --- 3. Per rank -----------------------------------------------------------
summary_rows <- list()
for (rk in ranks) {
  say("3. Rank: ", rk)
  t_rk <- tax[tax$want_rank == rk, c("name", "tax_id", "tax_name", "rank")]

  # One label per SV at this want_rank.
  check("each SV has at most one row at this want_rank", !anyDuplicated(t_rk$name))
  # One (tax_id, rank) per label, so the label alone identifies a row.
  lab <- unique(t_rk[c("tax_name", "tax_id", "rank")])
  check("each tax_name has a single tax_id and rank", !anyDuplicated(lab$tax_name))

  sv_lab <- setNames(t_rk$tax_name, t_rk$name)
  unlabelled <- !(long$sv %in% names(sv_lab))
  say("  SVs labelled: ", fmt(length(sv_lab)), "; long rows without a label: ",
      fmt(sum(unlabelled)), " (", fmt(sum(long$count[unlabelled])), " reads)")
  l2 <- long[!unlabelled, ]
  l2$label <- unname(sv_lab[l2$sv])
  key <- paste(l2$label, l2$specimen, sep = "\t")
  expected <- tapply(l2$count, key, sum)
  n_sv <- tapply(l2$count > 0, key, sum)  # SVs with reads, per (label, specimen)

  # tallies_wide
  w <- read_chr(file.path(base, sprintf("classify/tables/tallies_wide.%s.csv", rk)))
  hdr <- names(w)
  check("header: tax_name, tax_id, rank, then specimens",
        identical(hdr[1:3], c("tax_name", "tax_id", "rank")))
  check("every column has a non-empty, unique name",
        all(nzchar(hdr)) && !anyDuplicated(hdr))
  sp_cols <- hdr[-(1:3)]
  check("specimen columns == DADA2 specimens", setequal(sp_cols, specimens))
  check("one row per tax_name", !anyDuplicated(w$tax_name))
  m <- merge(w[c("tax_name", "tax_id", "rank")], lab, by = "tax_name",
             all.x = TRUE, suffixes = c("", ".svtax"))
  check("tax_id and rank equal those in sv_taxonomy",
        all(m$tax_id == m$tax_id.svtax & m$rank == m$rank.svtax))
  vals <- as.matrix(w[sp_cols])
  check("every cell is a non-negative integer", all(grepl("^[0-9]+$", vals)))
  num <- matrix(as.numeric(vals), nrow = nrow(vals), dimnames = list(w$tax_name, sp_cols))
  cell_key <- paste(rep(w$tax_name, times = length(sp_cols)),
                    rep(sp_cols, each = nrow(w)), sep = "\t")
  exp_cells <- expected[cell_key]
  exp_cells[is.na(exp_cells)] <- 0
  n_diff <- sum(as.vector(num) != exp_cells)
  check(sprintf("cells equal to the DADA2 sum (%s cells, %s differ)",
                fmt(length(num)), fmt(n_diff)), n_diff == 0)
  missing_combos <- setdiff(names(expected)[expected > 0], cell_key)
  check(sprintf("no labelled reads left out of the table (%s combos)",
                fmt(length(missing_combos))), length(missing_combos) == 0)
  col_tot <- colSums(num)
  tot_diff <- sum(col_tot[specimens] != dada2_tot[specimens])
  check(sprintf("specimen totals equal DADA2 (%s of %s differ)",
                tot_diff, length(specimens)), tot_diff == 0)
  if (tot_diff > 0) {
    say("    specimens whose total differs: ",
        paste(specimens[col_tot[specimens] != dada2_tot[specimens]], collapse = " "))
  }

  # by_specimen: one row per non-zero cell.
  #   tally      = the tallies_wide cell
  #   placements = SVs with reads carrying that label in that specimen
  #   freq       = tally / specimen total
  bs <- read_chr(file.path(base, sprintf("classify/tables/by_specimen.%s.csv", rk)))
  bkey <- paste(bs$tax_name, bs$specimen, sep = "\t")
  check("by_specimen: header specimen, tax_name, tax_id, rank, tally, placements, freq",
        identical(names(bs), c("specimen", "tax_name", "tax_id", "rank",
                               "tally", "placements", "freq")))
  check(sprintf("by_specimen: rows == non-zero cells (%s)", fmt(sum(num > 0))),
        nrow(bs) == sum(num > 0) && !anyDuplicated(bkey) &&
          setequal(bkey, cell_key[as.vector(num) > 0]))
  bs_tally <- as.numeric(bs$tally)
  check("by_specimen: tally == tallies_wide cell",
        all(bs_tally == num[cbind(bs$tax_name, bs$specimen)]))
  check("by_specimen: placements == SVs with reads",
        all(as.numeric(bs$placements) == n_sv[bkey]))
  rel_err <- abs(as.numeric(bs$freq) - bs_tally / dada2_tot[bs$specimen])
  check("by_specimen: freq == tally / specimen total (|diff| < 1e-12)",
        all(rel_err < 1e-12))

  # by_taxon: one row per taxon.
  #   tally, placements          = sums over specimens of the by_specimen columns
  #   avg_tally, avg_placements  = those sums / number of specimens
  #   avg_freq                   = sum of freq / number of specimens
  bt <- read_chr(file.path(base, sprintf("classify/tables/by_taxon.%s.csv", rk)))
  check("by_taxon: header tax_id, tax_name, rank, tally, placements, avg_*",
        identical(names(bt), c("tax_id", "tax_name", "rank", "tally", "placements",
                               "avg_tally", "avg_placements", "avg_freq")))
  agg <- function(col) tapply(as.numeric(bs[[col]]), bs$tax_name, sum)[bt$tax_name]
  n_sp <- length(specimens)
  check(sprintf("by_taxon: one row per taxon present (%s)", fmt(nrow(bt))),
        !anyDuplicated(bt$tax_name) && setequal(bt$tax_name, unique(bs$tax_name)))
  check("by_taxon: tally == sum of by_specimen tally",
        all(as.numeric(bt$tally) == agg("tally")))
  check("by_taxon: placements == sum of by_specimen placements",
        all(as.numeric(bt$placements) == agg("placements")))
  near <- function(a, b) all(abs(as.numeric(a) - b) <= 1e-9 * pmax(1, abs(b)))
  check("by_taxon: avg_tally == tally / specimens", near(bt$avg_tally, agg("tally") / n_sp))
  check("by_taxon: avg_placements == placements / specimens",
        near(bt$avg_placements, agg("placements") / n_sp))
  check("by_taxon: avg_freq == sum of freq / specimens", near(bt$avg_freq, agg("freq") / n_sp))

  summary_rows[[rk]] <- data.frame(
    rank = rk, taxa = nrow(w), specimens = length(sp_cols), cells = length(num),
    cells_differing = n_diff, total_reads = sum(num),
    unlabelled_reads = sum(long$count[unlabelled]))
  say("")
}

# --- 4. Summary ------------------------------------------------------------
say("4. Summary (DADA2 reads after chimera removal: ", fmt(sum(long$count)), ")")
s <- do.call(rbind, summary_rows)
s$total_reads <- fmt(s$total_reads)
s$cells <- fmt(s$cells)
s$unlabelled_reads <- fmt(s$unlabelled_reads)
print(s, row.names = FALSE, right = TRUE)
say("")
say("checks failed: ", n_fail)
if (n_fail > 0L) quit(status = 1L)
