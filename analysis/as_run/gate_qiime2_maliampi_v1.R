# ==============================================================================
# Gate de concordancia QIIME2/DADA2 vs MaLiAmPi a nivel de género
# Cohorte mexicana de microbiota vaginal (n = 111 muestras secuenciadas)
#
# Compara las dos tablas de género sobre taxones y muestras compartidas.
# Métricas: Spearman per-taxon, top-K Jaccard per-sample, Bray-Curtis per-sample,
# Mantel y Procrustes sobre matrices inter-muestra, cobertura de la intersección.
#
# Tono descriptivo: reporta números crudos, no emite veredictos.
#
# Author: Martin Ruhle (con co-work)
# Fecha: 2026-05-18
# ==============================================================================

# ---- 0. Paths configurables (EDITAR SI ES NECESARIO) -------------------------
PATH_MALIAMPI <- "C:/Users/marti/Documents/Datos_mexicanos/MaLiAmPi/archivos_extra/salida_analisis/classify/tables/tallies_wide.genus.csv"
PATH_QIIME2   <- "C:/Users/marti/Documents/Datos_mexicanos/genus_rel_filtered_conc_2026-03-06_abs.csv"
DIR_OUT       <- "outputs/gate_qiime2_maliampi"

# ---- 1. Setup de paquetes y verificación de versiones ------------------------
required_pkgs <- c("tidyverse", "vegan", "patchwork", "ggrepel", "scales")
missing_pkgs  <- setdiff(required_pkgs, rownames(installed.packages()))
if (length(missing_pkgs) > 0) {
  message("Instalando paquetes faltantes: ", paste(missing_pkgs, collapse = ", "))
  install.packages(missing_pkgs, repos = "https://cloud.r-project.org")
}
suppressPackageStartupMessages({
  library(tidyverse)
  library(vegan)
  library(patchwork)
  library(ggrepel)
  library(scales)
})

cat("\n=== Versiones ===\n")
cat("R:           ", R.version.string, "\n")
cat("tidyverse:   ", as.character(packageVersion("tidyverse")), "\n")
cat("vegan:       ", as.character(packageVersion("vegan")), "\n")
cat("patchwork:   ", as.character(packageVersion("patchwork")), "\n")
cat("ggrepel:     ", as.character(packageVersion("ggrepel")), "\n\n")

# ---- 2. Crear estructura de outputs ------------------------------------------
dir.create(file.path(DIR_OUT, "figuras"),  recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(DIR_OUT, "tablas"),   recursive = TRUE, showWarnings = FALSE)

# ==============================================================================
# 3. Cargar tabla MaLiAmPi
# ==============================================================================
# Formato: filas = entradas taxonómicas, cols = tax_name, tax_id, rank, <samples>
# Cada sample es Au<n>_S<m>. Filtramos por rank == "genus".
cat(">>> Cargando tabla MaLiAmPi...\n")
mal_raw <- read_csv(PATH_MALIAMPI, show_col_types = FALSE)
cat("  Dimensiones crudas: ", nrow(mal_raw), "x", ncol(mal_raw), "\n")
cat("  Distribución de rank:\n")
print(table(mal_raw$rank))

# Filtrar solo géneros
mal_g <- mal_raw |>
  filter(rank == "genus") |>
  select(-tax_id, -rank)
cat("  Géneros retenidos: ", nrow(mal_g), "\n")

# Limpiar sufijos de desambiguación NCBI tipo "Gordonia <high GC Gram+>".
# Rescata géneros homónimos que tienen forma "Nombre <comentario>".
mal_g <- mal_g |>
  mutate(tax_name = str_remove(tax_name, "\\s*<[^>]+>")) |>
  group_by(tax_name) |>
  summarise(across(everything(), sum), .groups = "drop")
cat("  Géneros tras limpieza de sufijos NCBI '<...>': ", nrow(mal_g), "\n")

# Detectar y reportar nombres compuestos (no match-eables sin curaduría)
mal_g <- mal_g |> mutate(is_composite = str_detect(tax_name, "/"))
n_composite <- sum(mal_g$is_composite)
cat("  Nombres compuestos en MaLiAmPi (excluidos del match): ", n_composite, "\n")
composite_names <- mal_g$tax_name[mal_g$is_composite]
mal_g <- mal_g |> filter(!is_composite) |> select(-is_composite)

# Pasar a formato long para facilitar manipulaciones
mal_long <- mal_g |>
  pivot_longer(-tax_name, names_to = "sample_full", values_to = "count") |>
  mutate(sample_id = str_remove(sample_full, "_S\\d+$"))
cat("  Muestras MaLiAmPi: ", n_distinct(mal_long$sample_id), "\n\n")

# ==============================================================================
# 4. Cargar tabla QIIME2/DADA2
# ==============================================================================
# Formato: filas = muestras, primeras N cols = géneros, resto = metadata clínica.
# Sample_id está en columna 'index_original'. Counts absolutos.
cat(">>> Cargando tabla QIIME2/DADA2...\n")
q2_raw <- read_csv(PATH_QIIME2, show_col_types = FALSE)
cat("  Dimensiones crudas: ", nrow(q2_raw), "x", ncol(q2_raw), "\n")

# Verificar que existan columnas clave
if (!"index_original" %in% names(q2_raw)) {
  stop("La tabla QIIME2 no tiene columna 'index_original'. Revisar formato.")
}

# Lista de columnas que NO son taxa (metadata clínica + identificadores)
meta_cols <- c("index", "id", "visita", "dg_visita", "sdg_visita", "dg_parto",
               "sdg_parto", "desenlace_parto", "edad_cronologicamujer",
               "peso_pregestacional_kg", "talla_mujer_cm", "imc_pregestacional",
               "imc_pregest_categ", "peso_kg", "calories", "calories_fat",
               "carbohydrates", "protein", "fat", "vitamin_b1", "vitamin_b2",
               "vitamin_b6", "vitamin_b12", "folic_ac_correg", "folate",
               "folate_dfe", "folate_food", "choline", "cystine", "glycine",
               "methionine", "serine", "dietsuppl3mon", "vitaminsup",
               "supintakefreq", "comp1tribleed", "compvaginf", "compsexualinf",
               "comppreeclam", "rpm_preterm", "rpm", "diabetes_gest", "obito",
               "oligohidramnios", "rciu", "bajo_peso_nac", "nivel_academico",
               "maritalstat", "workouthome", "sex_baby", "birthweightgr",
               "peso_nacimiento", "pfetal", "fcf", "ccef", "dbip", "cabd",
               "longfe", "hemoglobin_g_dl", "hemoglobin_alti_adj",
               "anemia_visita", "preterm", "early_preterm", "imc_visita",
               "lag_peso_kg", "lag_hemoglobin", "lag_imc_visita",
               "rolling_avg_peso", "rolling_avg_imc", "time_since_first",
               "index_original", "[BIB](ng/ul)1")
taxa_cols <- setdiff(names(q2_raw), meta_cols)
cat("  Columnas de taxa detectadas: ", length(taxa_cols), "\n")
cat("    (las primeras 5: ", paste(head(taxa_cols, 5), collapse = ", "), ")\n")

# Banderear duplicados (típicamente .1 al final de un género ya presente)
dup_taxa <- taxa_cols[str_detect(taxa_cols, "\\.1$")]
if (length(dup_taxa) > 0) {
  cat("  Sospechosos de duplicado (terminan en '.1'): ",
      paste(dup_taxa, collapse = ", "), "\n")
}

# Banderear taxa no-género (prefijos f__, o__, c__, d__)
non_genus_prefix <- str_detect(taxa_cols, "^[focdkpr]__")
cat("  Taxa con prefijo no-género (f__/o__/c__/d__): ", sum(non_genus_prefix), "\n")
cat("    Ejemplos: ",
    paste(head(taxa_cols[non_genus_prefix], 5), collapse = ", "), "\n")

# Quedarnos solo con muestras + taxa de QIIME2 (drop metadata clínica)
q2 <- q2_raw |>
  select(sample_id = index_original, all_of(taxa_cols)) |>
  pivot_longer(-sample_id, names_to = "tax_name", values_to = "count") |>
  mutate(count = replace_na(count, 0))
cat("  Muestras QIIME2: ", n_distinct(q2$sample_id), "\n\n")

# ==============================================================================
# 4b. Reagrupamiento SILVA 138 → NCBI Taxonomy (pre-2020)
# ------------------------------------------------------------------------------
# SILVA 138 adoptó divisiones taxonómicas recientes (Mesomycoplasma, Hoylesella,
# Segatella) que el ARF 2020-04-20 de MaLiAmPi no incorporó. Antes del match,
# colapsamos los géneros divididos en QIIME2 hacia su nombre legacy en MaLiAmPi.
# ==============================================================================

qiime_to_maliampi_inverse <- list(
  "Mycoplasma" = c("Mycoplasma"),
  "Prevotella" = c("Prevotella", "Hoylesella", "Segatella")
  # Extender con casos adicionales una vez confirmados los chequeos
)

cat(">>> Reagrupando géneros SILVA→NCBI en la tabla QIIME2...\n")
for (canonical in names(qiime_to_maliampi_inverse)) {
  components <- qiime_to_maliampi_inverse[[canonical]]
  present <- intersect(components, unique(q2$tax_name))
  if (length(present) < 2) {
    cat(sprintf("  [SKIP] %s: solo %d componente(s) presente(s) en QIIME2, no se colapsa.\n",
                canonical, length(present)))
    next
  }
  cat(sprintf("  [%s] %s -> %s (suma de counts en cada muestra)\n",
              canonical, paste(present, collapse = " + "), canonical))
  summed <- q2 |>
    filter(tax_name %in% present) |>
    group_by(sample_id) |>
    summarise(count = sum(count), .groups = "drop") |>
    mutate(tax_name = canonical)
  q2 <- q2 |>
    filter(!tax_name %in% present) |>
    bind_rows(summed)
}
cat(sprintf("  Taxa QIIME2 tras reagrupamiento: %d (era %d antes)\n\n",
            n_distinct(q2$tax_name), length(taxa_cols)))

# ==============================================================================
# 5. Mapeo taxonómico
# ==============================================================================
cat(">>> Construyendo mapeo taxonómico...\n")

mal_taxa <- unique(mal_long$tax_name)
q2_taxa  <- unique(q2$tax_name)

# Mapeo curado para casos especiales (extender según se necesite)
# Cada entrada: nombre QIIME2 -> vector de nombres MaLiAmPi a sumar
curated_map <- list(
  "Escherichia-Shigella" = c("Escherichia", "Shigella"),
  # Fannyhessea vaginae == ex Atopobium vaginae (reclasificación 2020).
  # MaLiAmPi/ARF 2020-04 conserva el nombre Atopobium.
  "Fannyhessea" = c("Atopobium")
)

# Verificar que los componentes del mapeo curado existan en MaLiAmPi
for (q_name in names(curated_map)) {
  mal_components <- curated_map[[q_name]]
  present <- mal_components[mal_components %in% mal_taxa]
  if (length(present) == 0) {
    cat("  [WARN] Para QIIME2 '", q_name,
        "', ningún componente MaLiAmPi presente: ",
        paste(mal_components, collapse = ", "), "\n", sep = "")
    curated_map[[q_name]] <- NULL
  } else {
    cat("  [OK] Match curado: '", q_name, "' <- suma(",
        paste(present, collapse = " + "), ")\n", sep = "")
    curated_map[[q_name]] <- present
  }
}

# Match exacto para el resto (case-sensitive, sin trimming porque ambos ya están limpios)
direct_match <- intersect(q2_taxa, mal_taxa)
direct_match <- setdiff(direct_match, names(curated_map))

q2_in_map     <- union(direct_match, names(curated_map))
q2_unmapped   <- setdiff(q2_taxa, q2_in_map)
mal_unmapped  <- setdiff(mal_taxa, unlist(c(direct_match, curated_map)))

cat("\n  Resumen del mapeo:\n")
cat("    QIIME2 taxa totales:           ", length(q2_taxa), "\n")
cat("    QIIME2 con match (incl. curado): ", length(q2_in_map), "\n")
cat("    QIIME2 sin match:              ", length(q2_unmapped), "\n")
cat("    MaLiAmPi taxa totales:         ", length(mal_taxa), "\n")
cat("    MaLiAmPi sin match:            ", length(mal_unmapped), "\n\n")

# Guardar listas de no-match para revisión humana
write_lines(sort(q2_unmapped),
            file.path(DIR_OUT, "tablas", "qiime2_taxa_sin_match.txt"))
write_lines(sort(mal_unmapped),
            file.path(DIR_OUT, "tablas", "maliampi_taxa_sin_match.txt"))
write_lines(sort(composite_names),
            file.path(DIR_OUT, "tablas", "maliampi_nombres_compuestos.txt"))

# ==============================================================================
# 6. Construir matrices paired (samples × taxa compartidos), en relativas
# ==============================================================================
cat(">>> Construyendo matrices paired...\n")

# Aplicar el mapeo: para QIIME2 cada taxon mapped queda igual; para MaLiAmPi
# las entradas curadas se suman.
# Producimos un long table con columna tax_unified (nombre QIIME2-style) por pipeline.

# MaLiAmPi: re-etiquetar usando el mapeo curado (combinar componentes)
mal_long_unified <- mal_long |>
  filter(tax_name %in% c(direct_match, unlist(curated_map))) |>
  mutate(tax_unified = tax_name)

# Reemplazar nombres de componentes curados por el nombre QIIME2 unificado
for (q_name in names(curated_map)) {
  mal_long_unified <- mal_long_unified |>
    mutate(tax_unified = if_else(tax_name %in% curated_map[[q_name]],
                                 q_name, tax_unified))
}

# Agregar counts por (sample, tax_unified) en MaLiAmPi
mal_agg <- mal_long_unified |>
  group_by(sample_id, tax_unified) |>
  summarise(count = sum(count), .groups = "drop") |>
  rename(tax_name = tax_unified)

# QIIME2: filtrar a taxa con match
q2_agg <- q2 |>
  filter(tax_name %in% q2_in_map)

# Intersección de muestras
samples_mal <- unique(mal_agg$sample_id)
samples_q2  <- unique(q2_agg$sample_id)
shared_samples <- intersect(samples_mal, samples_q2)
cat("  Muestras en MaLiAmPi:   ", length(samples_mal), "\n")
cat("  Muestras en QIIME2:     ", length(samples_q2), "\n")
cat("  Muestras compartidas:   ", length(shared_samples), "\n")
unique_mal <- setdiff(samples_mal, samples_q2)
unique_q2  <- setdiff(samples_q2, samples_mal)
if (length(unique_mal) > 0)
  cat("  Sólo en MaLiAmPi: ", paste(unique_mal, collapse = ", "), "\n")
if (length(unique_q2) > 0)
  cat("  Sólo en QIIME2:   ", paste(unique_q2, collapse = ", "), "\n")

shared_taxa <- q2_in_map
cat("  Taxa compartidos:       ", length(shared_taxa), "\n\n")

# Convertir long → wide (matriz samples × taxa) con counts absolutos
to_wide_counts <- function(df, samples, taxa) {
  m <- df |>
    filter(sample_id %in% samples, tax_name %in% taxa) |>
    pivot_wider(names_from = tax_name, values_from = count, values_fill = 0) |>
    arrange(sample_id)
  rn <- m$sample_id
  m <- as.matrix(m[, -1])
  rownames(m) <- rn
  # Asegurar mismo orden de columnas
  m <- m[, taxa[taxa %in% colnames(m)], drop = FALSE]
  m
}

mat_mal_abs <- to_wide_counts(mal_agg, shared_samples, shared_taxa)
mat_q2_abs  <- to_wide_counts(q2_agg,  shared_samples, shared_taxa)

# Verificar alineación
stopifnot(all(rownames(mat_mal_abs) == rownames(mat_q2_abs)))
stopifnot(all(colnames(mat_mal_abs) == colnames(mat_q2_abs)))

# ==============================================================================
# 7. Diagnóstico de cobertura ANTES de normalizar
# ==============================================================================
# Pregunta: qué fracción de la masa total por muestra en cada pipeline cae en
# los taxa compartidos? Si es baja, gran parte de la señal está fuera de la
# intersección y la comparación restringida es informativa pero parcial.

# Sumas totales por muestra en cada pipeline (sobre TODOS los taxa, no solo
# los compartidos)
mal_total_per_sample <- mal_long |>
  filter(sample_id %in% shared_samples) |>
  group_by(sample_id) |>
  summarise(total_all = sum(count), .groups = "drop")
q2_total_per_sample <- q2 |>
  filter(sample_id %in% shared_samples) |>
  group_by(sample_id) |>
  summarise(total_all = sum(count), .groups = "drop")

# Sumas en taxa compartidos
mal_shared_per_sample <- rowSums(mat_mal_abs)
q2_shared_per_sample  <- rowSums(mat_q2_abs)

coverage_df <- tibble(
  sample_id = shared_samples,
  total_mal = mal_total_per_sample$total_all[match(shared_samples,
                                                   mal_total_per_sample$sample_id)],
  shared_mal = mal_shared_per_sample[shared_samples],
  total_q2 = q2_total_per_sample$total_all[match(shared_samples,
                                                 q2_total_per_sample$sample_id)],
  shared_q2 = q2_shared_per_sample[shared_samples]
) |>
  mutate(
    pct_mal = shared_mal / total_mal,
    pct_q2  = shared_q2  / total_q2
  )

cat(">>> Cobertura de la intersección (% de masa por muestra en taxa compartidos):\n")
cat("  MaLiAmPi:  median = ", sprintf("%.3f", median(coverage_df$pct_mal)),
    " IQR = [", sprintf("%.3f", quantile(coverage_df$pct_mal, 0.25)), ", ",
    sprintf("%.3f", quantile(coverage_df$pct_mal, 0.75)), "]\n", sep = "")
cat("  QIIME2:    median = ", sprintf("%.3f", median(coverage_df$pct_q2)),
    " IQR = [", sprintf("%.3f", quantile(coverage_df$pct_q2, 0.25)), ", ",
    sprintf("%.3f", quantile(coverage_df$pct_q2, 0.75)), "]\n\n", sep = "")

write_csv(coverage_df, file.path(DIR_OUT, "tablas", "cobertura_interseccion.csv"))

# ==============================================================================
# 8. Convertir a abundancias relativas (sobre la masa COMPLETA del pipeline,
#    no sobre la intersección — es la representación honesta de cada pipeline)
# ==============================================================================
# Las relativas se normalizan al total por muestra DEL PIPELINE COMPLETO,
# de modo que sumen a 1 sobre todos los taxa del pipeline original. La matriz
# de "shared" terminará sumando menos de 1 por muestra (el resto cae en taxa
# no-compartidos), reflejando la cobertura.

mat_mal_rel <- sweep(mat_mal_abs, 1,
                     mal_total_per_sample$total_all[match(rownames(mat_mal_abs),
                                                          mal_total_per_sample$sample_id)],
                     "/")
mat_q2_rel  <- sweep(mat_q2_abs, 1,
                     q2_total_per_sample$total_all[match(rownames(mat_q2_abs),
                                                         q2_total_per_sample$sample_id)],
                     "/")

# Para los análisis de Bray-Curtis y Spearman intra-muestra, también
# precomputamos relativas restringidas a la intersección (suman 1 por fila)
mat_mal_rel_within <- sweep(mat_mal_abs, 1, rowSums(mat_mal_abs), "/")
mat_q2_rel_within  <- sweep(mat_q2_abs, 1, rowSums(mat_q2_abs), "/")

# ==============================================================================
# 9. Métrica A: Spearman per-taxon
# ==============================================================================
# Para cada taxón compartido, correlacionamos su vector de abundancia relativa
# (sobre la masa completa) a través de las muestras: rho(x_mal, x_q2).
cat(">>> Métrica A: Spearman per-taxon...\n")

per_taxon <- map_df(shared_taxa, function(tx) {
  v_mal <- mat_mal_rel[, tx]
  v_q2  <- mat_q2_rel[, tx]
  if (sum(v_mal > 0) < 3 || sum(v_q2 > 0) < 3) {
    return(tibble(taxon = tx, rho = NA_real_, p = NA_real_,
                  prev_mal = mean(v_mal > 0), prev_q2 = mean(v_q2 > 0),
                  mean_mal = mean(v_mal), mean_q2 = mean(v_q2)))
  }
  ct <- suppressWarnings(cor.test(v_mal, v_q2, method = "spearman", exact = FALSE))
  tibble(taxon = tx, rho = unname(ct$estimate), p = ct$p.value,
         prev_mal = mean(v_mal > 0), prev_q2 = mean(v_q2 > 0),
         mean_mal = mean(v_mal), mean_q2 = mean(v_q2))
}) |>
  arrange(desc(rho))

write_csv(per_taxon, file.path(DIR_OUT, "tablas", "spearman_per_taxon.csv"))

cat("  Spearman ρ resumen (n =", sum(!is.na(per_taxon$rho)),"taxa evaluables):\n")
cat("    median = ", sprintf("%.3f", median(per_taxon$rho, na.rm = TRUE)),
    "  IQR = [", sprintf("%.3f", quantile(per_taxon$rho, 0.25, na.rm = TRUE)),
    ", ", sprintf("%.3f", quantile(per_taxon$rho, 0.75, na.rm = TRUE)), "]\n",
    sep = "")
cat("    ρ > 0.7: ", sum(per_taxon$rho > 0.7, na.rm = TRUE), " taxa\n")
cat("    ρ < 0.3: ", sum(per_taxon$rho < 0.3, na.rm = TRUE), " taxa\n\n")

# ==============================================================================
# 10. Métrica B: Top-K Jaccard per-sample
# ==============================================================================
cat(">>> Métrica B: Top-K Jaccard per-sample (k = 5, 10)...\n")

topk_jaccard <- function(v1, v2, k) {
  t1 <- names(sort(v1, decreasing = TRUE))[1:min(k, length(v1))]
  t2 <- names(sort(v2, decreasing = TRUE))[1:min(k, length(v2))]
  length(intersect(t1, t2)) / length(union(t1, t2))
}

topk_df <- tibble(
  sample_id = rownames(mat_mal_rel_within),
  j_top5  = map_dbl(seq_len(nrow(mat_mal_rel_within)),
                    ~ topk_jaccard(mat_mal_rel_within[.x, ],
                                   mat_q2_rel_within[.x, ], 5)),
  j_top10 = map_dbl(seq_len(nrow(mat_mal_rel_within)),
                    ~ topk_jaccard(mat_mal_rel_within[.x, ],
                                   mat_q2_rel_within[.x, ], 10))
)

write_csv(topk_df, file.path(DIR_OUT, "tablas", "topk_jaccard_per_sample.csv"))

cat("  Jaccard top-5:  median = ", sprintf("%.3f", median(topk_df$j_top5)),
    "  IQR = [", sprintf("%.3f", quantile(topk_df$j_top5, 0.25)), ", ",
    sprintf("%.3f", quantile(topk_df$j_top5, 0.75)), "]\n", sep = "")
cat("  Jaccard top-10: median = ", sprintf("%.3f", median(topk_df$j_top10)),
    "  IQR = [", sprintf("%.3f", quantile(topk_df$j_top10, 0.25)), ", ",
    sprintf("%.3f", quantile(topk_df$j_top10, 0.75)), "]\n\n", sep = "")

# ==============================================================================
# 11. Métrica C: Bray-Curtis per-sample (paired) — sobre relativas restringidas
#     a la intersección (suma 1 por muestra), para comparar perfiles equivalentes.
# ==============================================================================
cat(">>> Métrica C: Bray-Curtis per-sample (paired)...\n")

bc_paired <- map_dbl(seq_len(nrow(mat_mal_rel_within)), function(i) {
  v1 <- mat_mal_rel_within[i, ]
  v2 <- mat_q2_rel_within[i, ]
  sum(abs(v1 - v2)) / sum(v1 + v2)
})

bc_df <- tibble(sample_id = rownames(mat_mal_rel_within), bray_curtis = bc_paired)
write_csv(bc_df, file.path(DIR_OUT, "tablas", "bray_curtis_per_sample.csv"))

cat("  Bray-Curtis distancias (0 = idéntico, 1 = totalmente distinto):\n")
cat("    median = ", sprintf("%.3f", median(bc_paired)),
    "  IQR = [", sprintf("%.3f", quantile(bc_paired, 0.25)),
    ", ", sprintf("%.3f", quantile(bc_paired, 0.75)), "]\n\n", sep = "")

# ==============================================================================
# 12. Métricas D + E: Mantel + Procrustes sobre matrices inter-muestra
# ==============================================================================
cat(">>> Métricas D + E: Mantel y Procrustes sobre matrices BC inter-muestra...\n")

# Matrices BC dentro de cada pipeline (sobre relativas-within, para evitar
# diferencias de escala absoluta)
d_mal <- vegdist(mat_mal_rel_within, method = "bray")
d_q2  <- vegdist(mat_q2_rel_within,  method = "bray")

set.seed(42)
mantel_res <- mantel(d_mal, d_q2, method = "spearman", permutations = 999)
cat("  Mantel r (Spearman):  ", sprintf("%.3f", mantel_res$statistic),
    "  p = ", sprintf("%.3g", mantel_res$signif), "  (999 permutaciones)\n", sep = "")

# Procrustes sobre PCoA (k = 5 ejes)
pcoa_mal <- cmdscale(d_mal, k = 5, eig = TRUE)
pcoa_q2  <- cmdscale(d_q2,  k = 5, eig = TRUE)
proc_res <- procrustes(pcoa_mal$points, pcoa_q2$points, symmetric = TRUE)
proc_test <- protest(pcoa_mal$points, pcoa_q2$points,
                     permutations = 999, symmetric = TRUE)
cat("  Procrustes M² (sym): ", sprintf("%.3f", proc_test$ss),
    "  correlación = ", sprintf("%.3f", proc_test$t0),
    "  p = ", sprintf("%.3g", proc_test$signif), "\n\n", sep = "")

# ==============================================================================
# 13. Figuras
# ==============================================================================
cat(">>> Generando figuras...\n")

# Figura 1: distribución de Spearman per-taxon + scatter ρ vs prevalencia
p_rho_hist <- per_taxon |>
  filter(!is.na(rho)) |>
  ggplot(aes(x = rho)) +
  geom_histogram(bins = 30, fill = "steelblue", color = "white") +
  geom_vline(xintercept = c(0.3, 0.7), linetype = "dashed", color = "grey40") +
  labs(x = "Spearman ρ (per taxon)", y = "Número de taxa",
       title = "Concordancia per-taxon entre MaLiAmPi y QIIME2",
       subtitle = sprintf("n = %d taxa compartidos",
                          sum(!is.na(per_taxon$rho)))) +
  theme_minimal(base_size = 11)

p_rho_prev <- per_taxon |>
  filter(!is.na(rho)) |>
  mutate(prev_mean = (prev_mal + prev_q2) / 2,
         abund_mean = (mean_mal + mean_q2) / 2) |>
  ggplot(aes(x = prev_mean, y = rho, size = abund_mean, label = taxon)) +
  geom_point(alpha = 0.6, color = "steelblue") +
  geom_text_repel(data = . %>% filter(rho < 0.3 | prev_mean > 0.4),
                  size = 2.7, max.overlaps = 25) +
  geom_hline(yintercept = c(0.3, 0.7), linetype = "dashed", color = "grey40") +
  scale_x_continuous(labels = scales::percent_format(accuracy = 1)) +
  scale_size_continuous(name = "Abundancia\nrelativa media",
                        labels = scales::percent_format(accuracy = 0.1)) +
  labs(x = "Prevalencia media (promedio entre pipelines)", y = "Spearman ρ",
       title = "Concordancia per-taxon vs prevalencia") +
  theme_minimal(base_size = 11)

ggsave(file.path(DIR_OUT, "figuras", "fig01_spearman_per_taxon.png"),
       p_rho_hist + p_rho_prev + plot_layout(widths = c(1, 1.4)),
       width = 12, height = 5, dpi = 150)

# Figura 2: cobertura de la intersección
p_cov <- coverage_df |>
  pivot_longer(c(pct_mal, pct_q2), names_to = "pipeline", values_to = "pct") |>
  mutate(pipeline = recode(pipeline, pct_mal = "MaLiAmPi", pct_q2 = "QIIME2")) |>
  ggplot(aes(x = pipeline, y = pct, fill = pipeline)) +
  geom_violin(alpha = 0.7) +
  geom_boxplot(width = 0.15, outlier.shape = NA, alpha = 0.6) +
  geom_jitter(width = 0.05, size = 0.6, alpha = 0.5) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1),
                     limits = c(0, 1)) +
  scale_fill_brewer(palette = "Set2", guide = "none") +
  labs(x = NULL, y = "Fracción de masa total por muestra en taxa compartidos",
       title = "Cobertura de la intersección de taxa por muestra") +
  theme_minimal(base_size = 11)

ggsave(file.path(DIR_OUT, "figuras", "fig02_cobertura_interseccion.png"),
       p_cov, width = 6, height = 5, dpi = 150)

# Figura 3: top-K Jaccard + Bray-Curtis per-sample
topk_long <- topk_df |>
  pivot_longer(c(j_top5, j_top10), names_to = "k", values_to = "jaccard") |>
  mutate(k = recode(k, j_top5 = "Top-5", j_top10 = "Top-10"))

p_topk <- ggplot(topk_long, aes(x = k, y = jaccard, fill = k)) +
  geom_violin(alpha = 0.7) +
  geom_boxplot(width = 0.15, outlier.shape = NA, alpha = 0.6) +
  geom_jitter(width = 0.05, size = 0.6, alpha = 0.5) +
  scale_fill_brewer(palette = "Set1", guide = "none") +
  ylim(0, 1) +
  labs(x = NULL, y = "Jaccard de top-K taxa más abundantes",
       title = "Concordancia de top taxa por muestra") +
  theme_minimal(base_size = 11)

p_bc <- ggplot(bc_df, aes(x = "", y = bray_curtis)) +
  geom_violin(fill = "darkorange", alpha = 0.7) +
  geom_boxplot(width = 0.15, outlier.shape = NA, alpha = 0.6) +
  geom_jitter(width = 0.05, size = 0.6, alpha = 0.5) +
  ylim(0, 1) +
  labs(x = "Bray-Curtis paired", y = "Distancia BC entre perfiles",
       title = "Distancia BC entre perfiles MaLiAmPi vs QIIME2 (misma muestra)") +
  theme_minimal(base_size = 11)

ggsave(file.path(DIR_OUT, "figuras", "fig03_per_sample.png"),
       p_topk + p_bc + plot_layout(widths = c(1.2, 1)),
       width = 11, height = 5, dpi = 150)

# Figura 4: Procrustes — superposición de PCoAs
proc_plot_df <- tibble(
  sample_id = rownames(mat_mal_rel_within),
  x_mal = pcoa_mal$points[, 1],
  y_mal = pcoa_mal$points[, 2],
  x_q2  = proc_res$Yrot[, 1],
  y_q2  = proc_res$Yrot[, 2]
)

p_proc <- ggplot(proc_plot_df) +
  geom_segment(aes(x = x_mal, y = y_mal, xend = x_q2, yend = y_q2),
               color = "grey60", alpha = 0.6) +
  geom_point(aes(x = x_mal, y = y_mal), color = "steelblue", size = 2,
             alpha = 0.7) +
  geom_point(aes(x = x_q2, y = y_q2), color = "darkorange", size = 2,
             alpha = 0.7) +
  labs(x = "PCoA1", y = "PCoA2",
       title = "Procrustes: MaLiAmPi (azul) vs QIIME2 (naranja)",
       subtitle = sprintf("M² = %.3f, correlación = %.3f, p = %.3g",
                          proc_test$ss, proc_test$t0, proc_test$signif)) +
  theme_minimal(base_size = 11)

ggsave(file.path(DIR_OUT, "figuras", "fig04_procrustes_pcoa.png"),
       p_proc, width = 7, height = 6, dpi = 150)

# ==============================================================================
# 14. Reporte final
# ==============================================================================
cat(">>> Escribiendo reporte...\n")

reporte <- c(
  "# Gate de concordancia QIIME2/DADA2 vs MaLiAmPi — Reporte",
  paste0("Fecha: ", Sys.Date()),
  "",
  "## Datos",
  sprintf("- MaLiAmPi: %d géneros, %d muestras (excluidos %d nombres compuestos).",
          length(unique(mal_long$tax_name)),
          n_distinct(mal_long$sample_id),
          n_composite),
  sprintf("- QIIME2:   %d taxa originales (%d con prefijo no-género), %d muestras.",
          length(taxa_cols),
          sum(non_genus_prefix),
          n_distinct(q2$sample_id)),
  "",
  "## Curación taxonómica aplicada",
  "- Limpieza de sufijos NCBI '<...>' en MaLiAmPi (ej. `Gordonia <high GC Gram+>` → `Gordonia`).",
  sprintf("- Reagrupamiento SILVA→NCBI en QIIME2: %s.",
          paste(sapply(names(qiime_to_maliampi_inverse), function(k)
            sprintf("%s ← %s", k, paste(qiime_to_maliampi_inverse[[k]], collapse = " + "))),
            collapse = "; ")),
  sprintf("- Mapeo curado adicional: %s.",
          paste(sapply(names(curated_map), function(k)
            sprintf("%s ↔ %s", k, paste(curated_map[[k]], collapse = " + "))),
            collapse = "; ")),
  "",
  sprintf("- Muestras compartidas: %d", length(shared_samples)),
  sprintf("- Taxa compartidos:     %d (match exacto: %d; mapeo curado: %d)",
          length(shared_taxa), length(direct_match), length(curated_map)),
  "",
  "## Cobertura de la intersección (% de masa por muestra en taxa compartidos)",
  sprintf("- MaLiAmPi:  median = %.3f, IQR [%.3f, %.3f]",
          median(coverage_df$pct_mal),
          quantile(coverage_df$pct_mal, 0.25),
          quantile(coverage_df$pct_mal, 0.75)),
  sprintf("- QIIME2:    median = %.3f, IQR [%.3f, %.3f]",
          median(coverage_df$pct_q2),
          quantile(coverage_df$pct_q2, 0.25),
          quantile(coverage_df$pct_q2, 0.75)),
  "",
  "## Concordancia per-taxon (Spearman)",
  sprintf("- median ρ = %.3f, IQR [%.3f, %.3f] (n = %d taxa evaluables)",
          median(per_taxon$rho, na.rm = TRUE),
          quantile(per_taxon$rho, 0.25, na.rm = TRUE),
          quantile(per_taxon$rho, 0.75, na.rm = TRUE),
          sum(!is.na(per_taxon$rho))),
  sprintf("- ρ > 0.7: %d taxa", sum(per_taxon$rho > 0.7, na.rm = TRUE)),
  sprintf("- ρ < 0.3: %d taxa", sum(per_taxon$rho < 0.3, na.rm = TRUE)),
  "",
  "## Concordancia per-sample",
  sprintf("- Jaccard top-5:    median = %.3f, IQR [%.3f, %.3f]",
          median(topk_df$j_top5),
          quantile(topk_df$j_top5, 0.25),
          quantile(topk_df$j_top5, 0.75)),
  sprintf("- Jaccard top-10:   median = %.3f, IQR [%.3f, %.3f]",
          median(topk_df$j_top10),
          quantile(topk_df$j_top10, 0.25),
          quantile(topk_df$j_top10, 0.75)),
  sprintf("- Bray-Curtis paired: median = %.3f, IQR [%.3f, %.3f]",
          median(bc_paired),
          quantile(bc_paired, 0.25),
          quantile(bc_paired, 0.75)),
  "",
  "## Estructura comunitaria (inter-muestra)",
  sprintf("- Mantel r (Spearman): %.3f, p = %.3g (999 permutaciones)",
          mantel_res$statistic, mantel_res$signif),
  sprintf("- Procrustes M² (sym): %.3f, correlación = %.3f, p = %.3g",
          proc_test$ss, proc_test$t0, proc_test$signif),
  "",
  "## Outputs generados",
  "- `tablas/spearman_per_taxon.csv` — todas las correlaciones per-taxon.",
  "- `tablas/topk_jaccard_per_sample.csv` — Jaccard top-5/top-10 por muestra.",
  "- `tablas/bray_curtis_per_sample.csv` — BC paired por muestra.",
  "- `tablas/cobertura_interseccion.csv` — % de masa en taxa compartidos por muestra.",
  "- `tablas/qiime2_taxa_sin_match.txt` — taxa de QIIME2 sin contraparte en MaLiAmPi.",
  "- `tablas/maliampi_taxa_sin_match.txt` — taxa de MaLiAmPi sin contraparte en QIIME2.",
  "- `tablas/maliampi_nombres_compuestos.txt` — entradas como 'X/Y' excluidas del match.",
  "- `figuras/fig01_spearman_per_taxon.png` — histograma + scatter ρ vs prevalencia.",
  "- `figuras/fig02_cobertura_interseccion.png` — violín de cobertura.",
  "- `figuras/fig03_per_sample.png` — top-K Jaccard + BC paired.",
  "- `figuras/fig04_procrustes_pcoa.png` — superposición PCoA."
)
writeLines(reporte, file.path(DIR_OUT, "reporte.md"))

cat("\n=== Listo. Outputs en:", DIR_OUT, "===\n")