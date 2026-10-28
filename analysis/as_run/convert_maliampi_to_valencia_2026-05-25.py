#!/usr/bin/env python3
# convert_maliampi_to_valencia.py
# Convierte tallies_wide.species.csv (MaLiAmPi) al formato de input de VALENCIA.
# Lee el header del centroide para validar nombres. Corre en WSL con el venv activo:
#   source ~/valencia_env/bin/activate
#   python3 convert_maliampi_to_valencia.py

import os
import re
import pandas as pd
import numpy as np

# ---- Paths configurables ----
PATH_SPECIES  = os.path.expanduser(
    "~/archivos_extra/salida_analisis/classify/tables/tallies_wide.species.csv")
PATH_CENTROID = os.path.expanduser("~/VALENCIA/CST_centroids_012920.csv")
PATH_OUT      = os.path.expanduser("~/valencia_input_maliampi.csv")

FOCALES = ["Lactobacillus", "Gardnerella", "Prevotella", "Atopobium", "Sneathia"]
LACTO_PRIORITY = ["crispatus", "iners", "gasseri", "jensenii"]

print(f"pandas {pd.__version__}, numpy {np.__version__}\n")

# ---- Leer columnas válidas del centroide (verdad de referencia) ----
centroid = pd.read_csv(PATH_CENTROID)
id_col = "sub_CST" if "sub_CST" in centroid.columns else centroid.columns[0]
centroid_taxa = set(centroid.columns) - {id_col, "sampleID", "read_count"}
print(f">>> Centroide: {len(centroid_taxa)} columnas de taxa")
foc_in_cent = sorted([t for t in centroid_taxa
                      if any(t.startswith(g) for g in FOCALES)])
print(f"    Focales en el centroide: {foc_in_cent}\n")

# ---- Cargar tabla de especies MaLiAmPi ----
df = pd.read_csv(PATH_SPECIES)
meta_cols = ["tax_name", "tax_id", "rank"]
sample_cols = [c for c in df.columns if c not in meta_cols]
print(f">>> MaLiAmPi: {df.shape[0]} filas, {len(sample_cols)} muestras\n")

# ---- Función de mapeo nombre MaLiAmPi → nombre VALENCIA ----
def map_to_valencia(tax_name, rank):
    # Primer token y primer componente de un posible compuesto "A/B"
    first = tax_name.split()[0] if " " in tax_name else tax_name
    genus = first.split("/")[0].split("_")[0]

    # --- Géneros focales ---
    if genus in FOCALES:
        if rank == "species" and " " in tax_name:
            species_field = tax_name.split(" ", 1)[1]
            sp_components = re.split(r"[/]", species_field)
            sp_components = [s.split("_")[-1] if "_" in s else s
                             for s in sp_components]  # limpia 'Genus_sp'

            if genus == "Lactobacillus":
                for foc in LACTO_PRIORITY:
                    if foc in sp_components:
                        cand = f"Lactobacillus_{foc}"
                        return cand if cand in centroid_taxa else "g_Lactobacillus"
                return "g_Lactobacillus"
            if genus == "Gardnerella":
                return "Gardnerella_vaginalis"
            if genus == "Atopobium":
                if "vaginae" in sp_components:
                    return ("Atopobium_vaginae"
                            if "Atopobium_vaginae" in centroid_taxa else "g_Atopobium")
                return "g_Atopobium"
            if genus == "Sneathia":
                sp = sp_components[0]
                cand = f"Sneathia_{sp}"
                return cand if cand in centroid_taxa else "g_Sneathia"
            if genus == "Prevotella":
                sp = sp_components[0]
                cand = f"Prevotella_{sp}"
                return cand if cand in centroid_taxa else "g_Prevotella"
        # Focal sin resolución a especie (rank genus)
        if genus == "Gardnerella":
            return "Gardnerella_vaginalis"
        return f"g_{genus}"

    # --- No focales ---
    if rank in ("genus", "species"):
        return f"g_{genus}"
    if rank in ("family", "family_"):
        return f"f_{genus}"
    # Ranks superiores a familia: masa no clasificable a género/familia.
    # Entra en read_count pero no matchea el centroide (penaliza, comportamiento correcto).
    return f"unclassified_{rank}"

# ---- Aplicar mapeo ----
df["valencia_name"] = [map_to_valencia(n, r)
                       for n, r in zip(df["tax_name"], df["rank"])]

# ---- Agregar counts por nombre VALENCIA ----
agg = df.groupby("valencia_name")[sample_cols].sum()

# ---- Transponer a muestras × taxa ----
mat = agg.T
mat.index.name = "sampleID_full"
mat = mat.reset_index()
mat["sampleID"] = mat["sampleID_full"].str.replace(r"_S\d+$", "", regex=True)

# ---- read_count = suma de TODA la masa de la muestra ----
taxa_value_cols = [c for c in mat.columns if c not in ("sampleID_full", "sampleID")]
mat["read_count"] = mat[taxa_value_cols].sum(axis=1)

# ---- Ordenar columnas: sampleID, read_count, taxa... ----
out = mat[["sampleID", "read_count"] + taxa_value_cols].copy()

# ---- Diagnóstico de cobertura contra el centroide ----
matched_cols   = [c for c in taxa_value_cols if c in centroid_taxa]
unmatched_cols = [c for c in taxa_value_cols if c not in centroid_taxa]

mass_total    = out[taxa_value_cols].sum().sum()
mass_matched  = out[matched_cols].sum().sum() if matched_cols else 0
print(f">>> Cobertura del centroide (masa total agregada):")
print(f"    Columnas que matchean centroide: {len(matched_cols)} / {len(taxa_value_cols)}")
print(f"    Fracción de masa en columnas reconocidas: {mass_matched/mass_total:.1%}\n")

# Cobertura por muestra (fracción de read_count en columnas reconocidas)
out["_matched"] = out[matched_cols].sum(axis=1) if matched_cols else 0
out["_cov"] = out["_matched"] / out["read_count"]
print(f"    Cobertura per-muestra: median {out['_cov'].median():.1%}, "
      f"min {out['_cov'].min():.1%}, max {out['_cov'].max():.1%}")
low_cov = out[out["_cov"] < 0.80][["sampleID", "_cov"]]
if len(low_cov):
    print(f"    Muestras con cobertura <80% (CST poco confiable): {len(low_cov)}")
    print(low_cov.to_string(index=False))
print()

# Top columnas no reconocidas por masa (para revisión)
if unmatched_cols:
    unmatched_mass = out[unmatched_cols].sum().sort_values(ascending=False)
    print(">>> Top 15 columnas NO reconocidas por el centroide (masa agregada):")
    for name, m in unmatched_mass.head(15).items():
        print(f"    {name:35s} {m/mass_total:5.2%}")
    print()

# ---- Escribir CSV (sin las columnas auxiliares) ----
out.drop(columns=["_matched", "_cov"]).to_csv(PATH_OUT, index=False)
print(f">>> Escrito: {PATH_OUT}")
print(f"    {out.shape[0]} muestras x {len(taxa_value_cols)} taxa\n")

print("Para correr VALENCIA:")
print(f"  python3 ~/VALENCIA/Valencia.py \\")
print(f"    -ref {PATH_CENTROID} \\")
print(f"    -i {PATH_OUT} \\")
print(f"    -o ~/valencia_output_maliampi \\")
print(f"    -p ~/valencia_plot_maliampi")