#!/usr/bin/env python3
"""Summarise a VALENCIA community state type assignment without exposing any specimen.

Reads the MaLiAmPi species table, the VALENCIA input written from it by
analysis/as_run/convert_maliampi_to_valencia_2026-05-25.py, the VALENCIA output and
the reference centroids. Prints only hashes, counts and mass fractions over the whole
cohort, and writes two count tables. With --compare, it also counts how many specimens
receive the same subCST in a second VALENCIA output (e.g. a re-run).

Runs in the VALENCIA environment (env/valencia-requirements.txt). Usage:

  python3 scripts/summarise_valencia_cst.py \
    --species  <MaLiAmPi out>/classify/tables/tallies_wide.species.csv \
    --input    <valencia input>.csv \
    --output   <valencia output>.csv \
    --centroids <VALENCIA clone>/CST_centroids_012920.csv \
    [--compare <second valencia output>.csv] \
    --out-dir  results/valencia_cst
"""
import argparse
import hashlib
import os

import numpy as np
import pandas as pd

SUBCSTS = ["I-A", "I-B", "II", "III-A", "III-B", "IV-A", "IV-B",
           "IV-C0", "IV-C1", "IV-C2", "IV-C3", "IV-C4", "V"]
CSTS = ["I", "II", "III", "IV-A", "IV-B", "IV-C", "V"]
FOCAL_LACTO = ["crispatus", "iners", "gasseri", "jensenii"]


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


def pct(x):
    return f"{100 * x:.2f} %"


ap = argparse.ArgumentParser()
for a in ("--species", "--input", "--output", "--centroids", "--out-dir"):
    ap.add_argument(a, required=True)
ap.add_argument("--compare")
args = ap.parse_args()

print(f"pandas {pd.__version__}, numpy {np.__version__}")
print("\n== Files (sha256)")
for label, path in [("species table", args.species), ("VALENCIA input", args.input),
                    ("VALENCIA output", args.output), ("centroids", args.centroids)] + \
                   ([("compared output", args.compare)] if args.compare else []):
    print(f"{label:16s} {sha256(path)}  {os.path.basename(path)}")

sp = pd.read_csv(args.species)
inp = pd.read_csv(args.input)
out = pd.read_csv(args.output)
cent = pd.read_csv(args.centroids)
cent_taxa = set(cent.columns) - {"sub_CST"}

spec_cols = [c for c in sp.columns if c not in ("tax_name", "tax_id", "rank")]
taxa_cols = [c for c in inp.columns if c not in ("sampleID", "read_count")]
total = sp[spec_cols].to_numpy().sum()

print("\n== Specimens")
print(f"species table: {len(spec_cols)} specimens, {len(sp)} taxa rows")
print(f"VALENCIA input: {len(inp)} specimens, {len(taxa_cols)} taxa columns")
print(f"VALENCIA output: {len(out)} specimens")
assert list(inp["sampleID"]) == list(out["sampleID"]), "input and output specimens differ"
assert inp["sampleID"].is_unique
assert inp[taxa_cols].to_numpy().sum() == total, "input does not hold every read of the species table"
assert (inp["read_count"] == inp[taxa_cols].sum(axis=1)).all(), "read_count is not the row total"
print("input holds every read of the species table; read_count == row total for every specimen")

print("\n== Conversion: where the reads go (fraction of all reads in the cohort)")
sp["mass"] = sp[spec_cols].sum(axis=1)
rank_mass = sp.groupby("rank")["mass"].sum()
sk = rank_mass[[r for r in rank_mass.index if r.startswith("superkingdom")]].sum()
print(f"rank 'species' in the MaLiAmPi table: {pct(rank_mass['species'] / total)}")
print(f"superkingdom-level ranks (kept in read_count, no centroid column): {pct(sk / total)}")
above_family = [c for c in taxa_cols if c.startswith("unclassified_")]
print(f"all ranks above family together (unclassified_*): "
      f"{pct(inp[above_family].to_numpy().sum() / total)}")

lacto = sp[sp["tax_name"].str.startswith("Lactobacillus")]
is_sp = lacto["rank"] == "species"
comps = lacto["tax_name"].str.split(" ", n=1).str[1].fillna("").str.split("/")
has_focal = comps.apply(lambda c: any(f in c for f in FOCAL_LACTO))
folded = lacto[~(is_sp & has_focal)]
assert folded["mass"].sum() == inp["g_Lactobacillus"].sum(), "g_Lactobacillus is not the folded labels"
print(f"g_Lactobacillus column: {pct(inp['g_Lactobacillus'].sum() / total)}, from "
      f"{len(folded)} Lactobacillus labels (genus level, compounds, and species other than "
      f"{', '.join(FOCAL_LACTO)})")
own = folded[folded["rank"].eq("species") &
             ("Lactobacillus_" + folded["tax_name"].str.split(" ", n=1).str[1]).isin(cent_taxa)]
print(f"  of which species with a column of their own in the centroids: "
      f"{', '.join(own['tax_name'])} ({pct(own['mass'].sum() / total)})")
gard_genus = sp.loc[(sp["tax_name"] == "Gardnerella") & (sp["rank"] == "genus"), "mass"].sum()
print(f"Gardnerella at genus level, written as Gardnerella_vaginalis: {pct(gard_genus / total)}")

print("\n== Coverage by the reference centroids")
matched = [c for c in taxa_cols if c in cent_taxa]
unmatched = [c for c in taxa_cols if c not in cent_taxa]
cov = inp[matched].sum(axis=1) / inp["read_count"]
print(f"taxa columns with a centroid column: {len(matched)} of {len(taxa_cols)}")
print(f"reads in those columns: {pct(inp[matched].to_numpy().sum() / total)}")
print(f"per specimen: median {pct(cov.median())}, min {pct(cov.min())}, max {pct(cov.max())}")
print(f"specimens below 80 %: {(cov < 0.80).sum()}")
um = (inp[unmatched].sum() / total).sort_values(ascending=False)
print("largest columns without a centroid column:")
for name, frac in um.head(8).items():
    print(f"  {name:30s} {pct(frac)}")

print("\n== Assignment")
sim_cols = [f"{s}_sim" for s in SUBCSTS]
assert np.allclose(out["score"], out[sim_cols].max(axis=1)), "score is not the best similarity"
sub_n = out["subCST"].value_counts().reindex(SUBCSTS, fill_value=0)
cst_n = out["CST"].value_counts().reindex(CSTS, fill_value=0)
assert sub_n.sum() == cst_n.sum() == len(out)
low = out["score"] < 0.5
sub_tab = pd.DataFrame({"subCST": SUBCSTS, "n": sub_n.values,
                        "n_similarity_below_0.5": out[low]["subCST"].value_counts()
                        .reindex(SUBCSTS, fill_value=0).values})
cst_tab = pd.DataFrame({"CST": CSTS, "n": cst_n.values,
                        "n_similarity_below_0.5": out[low]["CST"].value_counts()
                        .reindex(CSTS, fill_value=0).values})
print(cst_tab.to_string(index=False))
print()
print(sub_tab.to_string(index=False))
print(f"\nsimilarity to the assigned subCST: median {out['score'].median():.3f}, "
      f"min {out['score'].min():.3f}; below 0.5: {low.sum()} specimens")
print(f"specimens below 0.5 similarity and below 80 % coverage: {(low & (cov < 0.80)).sum()}")

if args.compare:
    cmp_out = pd.read_csv(args.compare)
    m = out[["sampleID", "subCST"]].merge(cmp_out[["sampleID", "subCST"]],
                                         on="sampleID", suffixes=("", "_cmp"))
    same = (m["subCST"] == m["subCST_cmp"]).sum()
    print(f"\n== Compared with {os.path.basename(args.compare)}")
    print(f"specimens in both: {len(m)}; same subCST: {same}; different: {len(m) - same}")
    print(f"byte-identical files: {sha256(args.output) == sha256(args.compare)}")

os.makedirs(args.out_dir, exist_ok=True)
cst_tab.to_csv(os.path.join(args.out_dir, "cst_counts.csv"), index=False)
sub_tab.to_csv(os.path.join(args.out_dir, "subcst_counts.csv"), index=False)
print(f"\nwrote cst_counts.csv and subcst_counts.csv to {args.out_dir}")
