#!/usr/bin/env python3
"""Summarise, by DREAM project, a VALENCIA assignment of DREAM Validation specimens.

Complements scripts/summarise_valencia_cst.py, which summarises the whole set and is run
on it unchanged. This script splits by project (K, V) and compares each specimen with the
community state type the Challenge distributes (community_state_types/cst_valencia.csv,
whose specimen column is called `specimen`, not `sampleID`). It prints and writes only
counts and read fractions: no specimen, participant or identifier leaves it.

Runs in the VALENCIA environment (env/valencia-requirements.txt). Usage:

  python3 scripts/summarise_valencia_cst_dream.py \
    --species   <dir>/tallies_wide.species.csv      (scripts/build_dream_species_table.py)
    --projects  <dir>/specimen_project.csv
    --input     <valencia input>.csv
    --output    <valencia output>.csv
    --dream-cst <unzipped Validation.zip>/Validation/community_state_types/cst_valencia.csv \
    --out-dir   results/valencia_cst_dream
"""
import argparse
import os

import pandas as pd

SUBCSTS = ["I-A", "I-B", "II", "III-A", "III-B", "IV-A", "IV-B",
           "IV-C0", "IV-C1", "IV-C2", "IV-C3", "IV-C4", "V"]
CSTS = ["I", "II", "III", "IV-A", "IV-B", "IV-C", "V"]

ap = argparse.ArgumentParser()
for a in ("--species", "--projects", "--input", "--output", "--dream-cst", "--out-dir"):
    ap.add_argument(a, required=True)
args = ap.parse_args()

sp = pd.read_csv(args.species)
proj = pd.read_csv(args.projects).set_index("specimen")["project"]
inp = pd.read_csv(args.input).set_index("sampleID")
out = pd.read_csv(args.output).set_index("sampleID")
dream = pd.read_csv(args.dream_cst).set_index("specimen")

assert set(out.index) == set(proj.index) == set(dream.index) == set(inp.index), \
    "specimen sets differ between the files"
df = pd.DataFrame({"project": proj, "CST": out["CST"], "subCST": out["subCST"],
                   "score": out["score"], "CST_DREAM": dream["CST"],
                   "subCST_DREAM": dream["subCST"], "score_DREAM": dream["score"]})
assert set(df["CST"]) <= set(CSTS) and set(df["CST_DREAM"]) <= set(CSTS)
assert set(df["subCST"]) <= set(SUBCSTS) and set(df["subCST_DREAM"]) <= set(SUBCSTS)

spec_cols = [c for c in sp.columns if c not in ("tax_name", "tax_id", "rank")]
reads = sp.groupby("tax_name")[spec_cols].sum()
top = reads.idxmax(axis=0)


def frac(names, specs):
    rows = reads.index.intersection(names)
    return reads.loc[rows, specs].to_numpy().sum() / reads[specs].to_numpy().sum()


cst_rows, sub_rows, cross_rows = [], [], []
groups = [("all", df)] + [(p, g) for p, g in df.groupby("project")]
for p, g in groups:
    specs = list(g.index)
    low, low_d = g["score"] < 0.5, g["score_DREAM"] < 0.5
    same_cst = (g["CST"] == g["CST_DREAM"]).sum()
    same_sub = (g["subCST"] == g["subCST_DREAM"]).sum()
    print(f"\n== Project {p}: {len(g)} specimens")
    print(f"same CST as the Challenge's: {same_cst} ({same_cst / len(g):.1%}); "
          f"same subCST: {same_sub} ({same_sub / len(g):.1%})")
    print(f"similarity < 0.5: this run {low.sum()} ({low.mean():.1%}); "
          f"the Challenge's assignment {low_d.sum()} ({low_d.mean():.1%})")
    print(f"Lactobacillus johnsonii: {frac(['Lactobacillus johnsonii'], specs):.2%} of the reads; "
          f"label with most reads in {(top[specs] == 'Lactobacillus johnsonii').sum()} specimens")
    print(f"Lactobacillus gasseri/johnsonii (compound): "
          f"{frac(['Lactobacillus gasseri/johnsonii'], specs):.2%} of the reads")
    f_lachno = inp.loc[specs, "f_Lachnospiraceae"].sum() / inp.loc[specs, "read_count"].sum()
    print(f"f_Lachnospiraceae column of the VALENCIA input: {f_lachno:.2%} of the reads")
    for c in CSTS:
        s = g[g["CST"] == c]
        cst_rows.append({"project": p, "CST": c, "n": len(s),
                         "n_similarity_below_0.5": int((s["score"] < 0.5).sum()),
                         "n_same_CST_as_DREAM": int((s["CST"] == s["CST_DREAM"]).sum()),
                         "n_DREAM": int((g["CST_DREAM"] == c).sum())})
    for c in SUBCSTS:
        s = g[g["subCST"] == c]
        sub_rows.append({"project": p, "subCST": c, "n": len(s),
                         "n_similarity_below_0.5": int((s["score"] < 0.5).sum()),
                         "n_same_subCST_as_DREAM": int((s["subCST"] == s["subCST_DREAM"]).sum()),
                         "n_DREAM": int((g["subCST_DREAM"] == c).sum())})
    ct = pd.crosstab(g["CST"], g["CST_DREAM"]).reindex(index=CSTS, columns=CSTS, fill_value=0)
    for a in CSTS:
        for b in CSTS:
            if ct.loc[a, b]:
                cross_rows.append({"project": p, "CST": a, "CST_DREAM": b, "n": int(ct.loc[a, b])})

cst_tab, sub_tab = pd.DataFrame(cst_rows), pd.DataFrame(sub_rows)
cross = pd.DataFrame(cross_rows)
for t, key in ((cst_tab, "CST"), (sub_tab, "subCST")):
    for p, g in t.groupby("project"):
        assert g["n"].sum() == g["n_DREAM"].sum() == (df if p == "all" else df[df.project == p]).shape[0]
print("\n== CST by project (n_DREAM: the Challenge's own assignment)")
print(cst_tab.to_string(index=False))
print("\n== subCST by project")
print(sub_tab.to_string(index=False))
print("\n== CST of this run (rows) against the Challenge's (CST_DREAM), non-zero cells")
print(cross.to_string(index=False))

os.makedirs(args.out_dir, exist_ok=True)
cst_tab.to_csv(os.path.join(args.out_dir, "cst_by_project.csv"), index=False)
sub_tab.to_csv(os.path.join(args.out_dir, "subcst_by_project.csv"), index=False)
cross.to_csv(os.path.join(args.out_dir, "cst_vs_dream_by_project.csv"), index=False)
print(f"\nwrote cst_by_project.csv, subcst_by_project.csv and cst_vs_dream_by_project.csv "
      f"to {args.out_dir}")
