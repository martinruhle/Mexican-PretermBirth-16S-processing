#!/usr/bin/env python3
"""Build a MaLiAmPi-style species table (tallies_wide.species.csv) from DREAM Validation.

The DREAM Challenge distributes its taxonomy tables with specimens as rows and only the
taxon name as column: no tax_id and no rank, which the cohort's VALENCIA converter
(analysis/as_run/convert_maliampi_to_valencia_2026-05-25.py) needs. Both can be rebuilt
from two other files of the same archive:

  sv_counts/sp_sv_long.csv   reads per specimen and sequence variant (with total_reads)
  taxonomy/sv_taxonomy.csv   the classification of each variant at every want_rank

Rows of sv_taxonomy.csv with want_rank == "species" give, for each variant, the label it
reaches when species is asked for (tax_name, tax_id, rank). Rows with an empty sv are
left out: they carry no variant to join on.

The table is accepted only if, summed by tax_name, it equals
taxonomy/taxonomy_nreads.species.full.csv cell by cell, and every specimen's column sums
to its total_reads. The output holds per-specimen counts and is written outside the
repository; this script prints only counts.

Runs in the VALENCIA environment (env/valencia-requirements.txt). Usage:

  python3 scripts/build_dream_species_table.py \
    --validation-dir <unzipped Validation.zip>/Validation \
    --out <dir>/tallies_wide.species.csv \
    --projects <dir>/specimen_project.csv
"""
import argparse
import os

import pandas as pd

ap = argparse.ArgumentParser()
for a in ("--validation-dir", "--out", "--projects"):
    ap.add_argument(a, required=True)
args = ap.parse_args()
d = args.validation_dir

print(f"pandas {pd.__version__}")
long = pd.read_csv(os.path.join(d, "sv_counts", "sp_sv_long.csv"))
tax = pd.read_csv(os.path.join(d, "taxonomy", "sv_taxonomy.csv"), dtype={"tax_id": str})
full = pd.read_csv(os.path.join(d, "taxonomy", "taxonomy_nreads.species.full.csv"),
                   index_col="specimen")
short = pd.read_csv(os.path.join(d, "taxonomy", "taxonomy_nreads.species.csv"),
                    index_col="specimen")

print("\n== sp_sv_long.csv")
# Some specimens list a variant on more than one row; total_reads counts every row, so
# the rows are added (and the .full check below confirms the distributed table does too).
dup = long.duplicated(["specimen", "sv"], keep=False)
print(f"(specimen, variant) pairs on more than one row: "
      f"{long[dup].drop_duplicates(['specimen', 'sv']).shape[0]}, in "
      f"{long.loc[dup, 'specimen'].nunique()} specimens; their rows are added")
per_spec = long.groupby("specimen").agg(nreads=("nreads", "sum"),
                                        tr_min=("total_reads", "min"),
                                        tr_max=("total_reads", "max"))
assert (per_spec["tr_min"] == per_spec["tr_max"]).all(), "total_reads varies within a specimen"
assert (per_spec["nreads"] == per_spec["tr_min"]).all(), "nreads do not sum to total_reads"
proj = long[["specimen", "project"]].drop_duplicates()
assert proj["specimen"].is_unique, "a specimen belongs to two projects"
print(f"{len(long)} rows, {long['sv'].nunique()} variants, {len(per_spec)} specimens, "
      f"{long['nreads'].sum()} reads; nreads sum to total_reads in every specimen")
print("specimens by project: " +
      ", ".join(f"{p} {n}" for p, n in proj["project"].value_counts().sort_index().items()))

print("\n== sv_taxonomy.csv, want_rank == species")
sp = tax[tax["want_rank"] == "species"]
empty = sp["sv"].isna() | (sp["sv"].astype(str).str.strip() == "")
print(f"{len(sp)} rows; {empty.sum()} with an empty sv, left out")
sp = sp[~empty]
assert sp["sv"].is_unique, "a variant has two species-level rows"
missing = set(long["sv"]) - set(sp["sv"])
assert not missing, f"{len(missing)} variants in sp_sv_long.csv have no species-level row"
print(f"{len(sp)} variants classified; every variant in sp_sv_long.csv is among them")

m = long.merge(sp[["sv", "tax_name", "tax_id", "rank"]], on="sv", how="left", validate="m:1")
wide = (m.pivot_table(index=["tax_name", "tax_id", "rank"], columns="specimen",
                      values="nreads", aggfunc="sum", fill_value=0)
        .astype("int64"))
wide = wide[list(full.index)]  # specimens in the order of the distributed table
wide.columns.name = None
labels = wide.reset_index()
print(f"\n== Table built: {len(wide)} rows (tax_name, tax_id, rank), {wide.shape[1]} specimens, "
      f"{labels['tax_name'].nunique()} distinct tax_name")
print("rows by rank: " + ", ".join(f"{r} {n}" for r, n in
                                    labels["rank"].value_counts().sort_index().items()))

print("\n== Checks")
by_name = wide.groupby(level="tax_name").sum().T
assert set(by_name.columns) == set(full.columns), "label sets differ from the .full table"
assert set(by_name.index) == set(full.index), "specimen sets differ from the .full table"
fv = full.loc[by_name.index, by_name.columns]
assert (fv.to_numpy() == fv.to_numpy().round()).all(), "the .full table holds non-integer counts"
assert (by_name.to_numpy() == fv.to_numpy().astype("int64")).all(), "cell values differ"
print(f"summed by tax_name, equal cell by cell to taxonomy_nreads.species.full.csv "
      f"({full.shape[0]} specimens x {full.shape[1]} labels)")
col_tot = wide.sum(axis=0)
assert (col_tot == per_spec.loc[col_tot.index, "nreads"]).all()
print("every specimen's column sums to its total_reads")
lost_labels = sorted(set(full.columns) - set(short.columns))
print(f"for reference, taxonomy_nreads.species.csv (not used) lacks {len(lost_labels)} labels "
      f"and {int(full.to_numpy().sum() - short.to_numpy().sum())} reads of the .full table")

os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
wide.reset_index().to_csv(args.out, index=False)
proj.sort_values("specimen").to_csv(args.projects, index=False)
print(f"\nwrote {os.path.basename(args.out)} and {os.path.basename(args.projects)} "
      "(per-specimen, outside the repository)")
