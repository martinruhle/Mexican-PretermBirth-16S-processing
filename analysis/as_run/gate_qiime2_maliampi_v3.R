# ==============================================================================
# Gate de concordancia QIIME2/DADA2 vs MaLiAmPi
# Cohorte mexicana de microbiota vaginal (n = 111 muestras secuenciadas)
#
# v3 (2026-09-21) — Cambios respecto a v2, y NADA mas:
#   [v3] En PATH_QIIME2, 4 de las 110 filas llevan los conteos de OTRA muestra
#        (Au52<->Au197, Au179<->Au203) aunque su etiqueta index_original sea
#        correcta. v3 toma la etiqueta de cada fila del mapa canonico
#        (PATH_MAPA, via 'index'), exige que coincida con index_original, y
#        reemplaza los 97 conteos de cada fila por los del crudo de QIIME2
#        (PATH_QIIME2_CRUDO) para ese Au. Ver bloque 4a.
#   [v3] CURACION_EXTENDIDA se lee de la variable de entorno
#        GATE_CURACION_EXTENDIDA (default TRUE, como en v2) para correr ambas
#        variantes sin editar el archivo.
#   Nombres de taxa, orden de columnas, curacion, semilla y metricas: identicos a v2.
#
# v2 (2026-05-22) — Cambios respecto al script original:
#   [TAREA 1c] Cobertura ahora se calcula en DOS variantes por track:
#              (a) asimetrica  -> denominador = masa total del pipeline tal cual
#                                 entra a la funcion (replica el comportamiento
#                                 original; deja trazabilidad con reporte previo).
#              (b) simetrica   -> denominador de CADA pipeline restringido a su
#                                 propio universo del MISMO nivel taxonomico que
#                                 participa del match. Elimina la asimetria del
#                                 denominador diagnosticada en la auditoria.
#   [TAREA 2]  Secciones 6-13 del script original refactorizadas en la funcion
#              run_track(), que acepta tablas long pre-procesadas. Se corre dos
#              veces: track "genus" (identico al original) y track "all_taxa".
#   [TAREA 2]  Outputs separados en tablas/<track>/ y figuras/<track>/.
#   [TAREA 2]  curated_map se construye dinamicamente: solo se activan las
#              entradas cuyos componentes existen en los datos de cada track.
#
# NOTA DE AUDITORIA: el reporte.md provisto menciona curacion (Mycoplasma+
# Mesomycoplasma, Prevotella+Hoylesella+Segatella, Fannyhessea<-Atopobium,
# limpieza de sufijos NCBI '<...>') que NO estaba en el script original provisto.
# Esa curacion se agrega abajo en bloques claramente marcados [CURACION EXTENDIDA]
# y limpieza_ncbi(). Si el script original verdadero ya no la tenia, son no-ops
# inofensivos (solo se activan donde los componentes existen).
#
# Author: Martin Ruhle (con co-work)
# ==============================================================================

# ---- 0. Paths configurables (EDITAR SI ES NECESARIO) -------------------------
PATH_MALIAMPI <- "C:/Users/marti/Documents/Datos_mexicanos/MaLiAmPi/archivos_extra/salida_analisis/classify/tables/tallies_wide.genus.csv"
PATH_QIIME2   <- "C:/Users/marti/Documents/Datos_mexicanos/genus_rel_filtered_conc_2026-03-06_abs.csv"
PATH_QIIME2_CRUDO <- "C:/Users/marti/Documents/Datos_mexicanos/level-6_vag138.xlsx"
PATH_MAPA     <- "C:/Users/marti/Documents/Datos_mexicanos/mapa_muestras_2026-09-20.csv"
DIR_OUT       <- "outputs/gate_qiime2_maliampi"

# ---- 0b. Flag de curacion extendida (DECISION CONSCIENTE REQUERIDA) ----------
# El reporte.md previo refleja curacion (limpieza NCBI '<...>', merge SILVA
# Mycoplasma+Mesomycoplasma / Prevotella+Hoylesella+Segatella, Fannyhessea<-
# Atopobium) que NO estaba en el script original. NO se pudo confirmar si esa
# curacion era parte del script verdadero o si el reporte se edito a mano.
#
# Por eso queda APAGADA por defecto. Procedimiento para decidir:
#   1) Correr con FALSE. Comparar el track 'genus' contra el reporte.md viejo.
#   2) Si NO reproduce los numeros viejos (median rho=0.530, 13 taxa rho>0.7,
#      mapeo curado=2), correr con TRUE y volver a comparar.
#   3) La variante que reproduzca el reporte viejo es la curacion verdadera.
# Activar SOLO con esa evidencia, no por inercia del reporte huerfano.
CURACION_EXTENDIDA <- as.logical(Sys.getenv("GATE_CURACION_EXTENDIDA", "TRUE"))
stopifnot(!is.na(CURACION_EXTENDIDA))
cat("CURACION_EXTENDIDA =", CURACION_EXTENDIDA, "\n")

# ---- 1. Setup de paquetes y verificacion de versiones ------------------------
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

# ==============================================================================
# 2. Helpers de bajo nivel (compartidos por ambos tracks)
# ==============================================================================

# Limpieza de sufijos NCBI tipo "Gordonia <high GC Gram+>" -> "Gordonia".
# [CURACION EXTENDIDA] El reporte previo la menciona; se aplica a MaLiAmPi.
limpieza_ncbi <- function(x) {
  x |>
    str_replace_all("\\s*<[^>]*>", "") |>   # quita "<...>" y el espacio previo
    str_trim()
}

# long -> wide (matriz samples x taxa), counts absolutos, alineada por nombre.
to_wide_counts <- function(df, samples, taxa) {
  m <- df |>
    filter(sample_id %in% samples, tax_name %in% taxa) |>
    pivot_wider(names_from = tax_name, values_from = count, values_fill = 0) |>
    arrange(sample_id)
  rn <- m$sample_id
  m <- as.matrix(m[, setdiff(colnames(m), "sample_id"), drop = FALSE])
  rownames(m) <- rn
  # Asegurar mismo orden/conjunto de columnas que 'taxa' (las presentes)
  m <- m[, taxa[taxa %in% colnames(m)], drop = FALSE]
  m
}

# Jaccard de los top-K taxa mas abundantes de dos vectores nombrados.
topk_jaccard <- function(v1, v2, k) {
  t1 <- names(sort(v1, decreasing = TRUE))[1:min(k, length(v1))]
  t2 <- names(sort(v2, decreasing = TRUE))[1:min(k, length(v2))]
  length(intersect(t1, t2)) / length(union(t1, t2))
}

# Construye el curated_map activo para un track dado: conserva solo las entradas
# cuyos componentes existen en mal_taxa. Imprime [OK]/[WARN] por entrada.
build_curated_map <- function(curated_template, mal_taxa, etiqueta = "") {
  cm <- list()
  for (q_name in names(curated_template)) {
    comp    <- curated_template[[q_name]]
    present <- comp[comp %in% mal_taxa]
    if (length(present) == 0) {
      cat("  [", etiqueta, "][WARN] '", q_name,
          "': ningun componente MaLiAmPi presente (",
          paste(comp, collapse = ", "), ")\n", sep = "")
    } else {
      cat("  [", etiqueta, "][OK] '", q_name, "' <- suma(",
          paste(present, collapse = " + "), ")\n", sep = "")
      cm[[q_name]] <- present
    }
  }
  cm
}

# ==============================================================================
# 3. Cargar y preparar MaLiAmPi (crudo)
# ==============================================================================
# Formato: filas = entradas taxonomicas, cols = tax_name, tax_id, rank, <samples>.
# Cada sample es Au<n>_S<m>.
cat(">>> Cargando tabla MaLiAmPi...\n")
mal_raw <- read_csv(PATH_MALIAMPI, show_col_types = FALSE)
cat("  Dimensiones crudas: ", nrow(mal_raw), "x", ncol(mal_raw), "\n")
cat("  Distribucion de rank:\n")
print(table(mal_raw$rank))

# [CURACION EXTENDIDA] Limpieza NCBI al nombre ANTES de cualquier filtro/match.
# Solo si CURACION_EXTENDIDA == TRUE (ver bloque 0b).
if (CURACION_EXTENDIDA) {
  n_afect <- sum(str_detect(mal_raw$tax_name, "<[^>]*>"), na.rm = TRUE)
  mal_raw <- mal_raw |> mutate(tax_name = limpieza_ncbi(tax_name))
  cat("  [CURACION_EXTENDIDA] limpieza NCBI aplicada a ", n_afect, " nombres.\n")
}

# Funcion que produce el mal_long de un track a partir de mal_raw.
#   solo_genero = TRUE  -> filtra rank == "genus"  (track genus)
#   solo_genero = FALSE -> conserva todos los ranks (track all_taxa)
# En ambos casos: dropea tax_id/rank, excluye nombres compuestos ("X/Y"),
# pivotea a long y deriva sample_id.
prep_mal_long <- function(mal_raw, solo_genero) {
  m <- mal_raw
  if (solo_genero) m <- m |> filter(rank == "genus")
  m <- m |> select(-any_of(c("tax_id", "rank")))
  
  composite <- str_detect(m$tax_name, "/")
  composite_names <- m$tax_name[composite]
  m <- m[!composite, , drop = FALSE]
  
  ml <- m |>
    pivot_longer(-tax_name, names_to = "sample_full", values_to = "count") |>
    mutate(
      count     = replace_na(count, 0),
      sample_id = str_remove(sample_full, "_S\\d+$")
    )
  # Si un mismo tax_name aparece >1 vez tras quitar rank (posible en all_taxa
  # cuando el mismo nombre existe en >1 nivel), agregamos por (tax_name,sample).
  ml <- ml |>
    group_by(tax_name, sample_id) |>
    summarise(count = sum(count), .groups = "drop")
  
  attr(ml, "composite_names") <- sort(unique(composite_names))
  ml
}

mal_long_genus <- prep_mal_long(mal_raw, solo_genero = TRUE)
mal_long_all   <- prep_mal_long(mal_raw, solo_genero = FALSE)
cat("  [genus]    generos retenidos: ", n_distinct(mal_long_genus$tax_name),
    " | compuestos excluidos: ", length(attr(mal_long_genus, "composite_names")), "\n")
cat("  [all_taxa] taxa retenidos:    ", n_distinct(mal_long_all$tax_name),
    " | compuestos excluidos: ", length(attr(mal_long_all, "composite_names")), "\n")
cat("  Muestras MaLiAmPi: ", n_distinct(mal_long_genus$sample_id), "\n\n")

# ==============================================================================
# 4. Cargar y preparar QIIME2/DADA2 (crudo)
# ==============================================================================
# Formato: filas = muestras, primeras N cols = taxa, resto = metadata clinica.
# Sample_id en columna 'index_original'. Counts absolutos.
cat(">>> Cargando tabla QIIME2/DADA2...\n")
q2_raw <- read_csv(PATH_QIIME2, show_col_types = FALSE)
cat("  Dimensiones crudas: ", nrow(q2_raw), "x", ncol(q2_raw), "\n")
if (!"index_original" %in% names(q2_raw)) {
  stop("La tabla QIIME2 no tiene columna 'index_original'. Revisar formato.")
}

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

# ---- 4a. [v3] Conteos QIIME2 re-anclados al crudo por el mapa canonico -------
# Vinculo Au -> fila: SOLO del mapa canonico (via 'index'). index_original debe
# coincidir; si no, se detiene. Los conteos de cada fila se toman del crudo de
# QIIME2 (filas identificadas por el sample-id de QIIME2 = Au###).
suppressPackageStartupMessages(library(readxl))
mapa <- read_csv(PATH_MAPA, show_col_types = FALSE)
q2_crudo <- as.data.frame(read_excel(PATH_QIIME2_CRUDO, .name_repair = "minimal"))
CNT <- as.matrix(q2_crudo[, str_detect(names(q2_crudo), "__"), drop = FALSE])
storage.mode(CNT) <- "numeric"
rownames(CNT) <- q2_crudo$index
stopifnot(ncol(CNT) == length(taxa_cols), !anyDuplicated(rownames(CNT)))

au_mapa <- mapa$Au[match(q2_raw$index, mapa$index)]
stopifnot(!anyNA(au_mapa),
          identical(au_mapa, q2_raw$index_original),
          setequal(au_mapa, mapa$Au[mapa$en_analisis == "si"]),
          all(au_mapa %in% rownames(CNT)))

# Mismo orden de columnas en crudo y en PATH_QIIME2: cada fila de PATH_QIIME2
# tiene que ser identica a exactamente una fila del crudo.
huella <- function(m) apply(m, 1, paste, collapse = ",")
h_q2    <- huella(as.matrix(q2_raw[, taxa_cols]))
h_crudo <- huella(CNT)
stopifnot(all(h_q2 %in% h_crudo), !anyDuplicated(h_q2))

ajenas <- au_mapa[h_q2 != h_crudo[au_mapa]]
cat("  [v3] Filas cuyos conteos eran de otra muestra: ", length(ajenas),
    if (length(ajenas)) paste0("(", paste(ajenas, collapse = ", "), ")") else "", "\n")
reemplazo <- as.data.frame(CNT[au_mapa, , drop = FALSE])
names(reemplazo) <- taxa_cols
q2_raw[taxa_cols] <- reemplazo
stopifnot(all(rowSums(q2_raw[taxa_cols]) == mapa$conteos_qiime[match(au_mapa, mapa$Au)]))
cat("  [v3] Conteos re-anclados al crudo; totales por muestra == mapa$conteos_qiime\n")

dup_taxa <- taxa_cols[str_detect(taxa_cols, "\\.1$")]
if (length(dup_taxa) > 0)
  cat("  Sospechosos de duplicado (terminan en '.1'): ",
      paste(dup_taxa, collapse = ", "), "\n")

non_genus_prefix <- str_detect(taxa_cols, "^[focdkpr]__")
cat("  Taxa con prefijo no-genero (f__/o__/c__/d__/...): ", sum(non_genus_prefix), "\n")

# q2 long crudo, con TODOS los taxa_cols (la seleccion por track se hace despues).
q2_long_all <- q2_raw |>
  select(sample_id = index_original, all_of(taxa_cols)) |>
  pivot_longer(-sample_id, names_to = "tax_name", values_to = "count") |>
  mutate(count = replace_na(count, 0))

# [CURACION EXTENDIDA] Reagrupamiento SILVA->NCBI dentro de QIIME2: sumar
# sinonimos a un nombre canonico (Mycoplasma, Prevotella). Se hace ANTES del
# match. Solo afecta filas cuyos nombres existan; el resto pasa intacto.
# Solo si CURACION_EXTENDIDA == TRUE (ver bloque 0b).
if (CURACION_EXTENDIDA) {
  q2_silva_merge <- list(
    "Mycoplasma" = c("Mycoplasma", "Mesomycoplasma"),
    "Prevotella" = c("Prevotella", "Hoylesella", "Segatella")
  )
  for (canon in names(q2_silva_merge)) {
    syns <- q2_silva_merge[[canon]]
    presentes <- intersect(syns, unique(q2_long_all$tax_name))
    if (length(presentes) > 1) {
      q2_long_all <- q2_long_all |>
        mutate(tax_name = if_else(tax_name %in% syns, canon, tax_name))
      cat("  [CURACION_EXTENDIDA] SILVA merge '", canon, "' <- ",
          paste(presentes, collapse = " + "), "\n", sep = "")
    }
  }
  # Tras renombrar pueden quedar duplicados (canon + sinonimo): agregamos.
  q2_long_all <- q2_long_all |>
    group_by(sample_id, tax_name) |>
    summarise(count = sum(count), .groups = "drop")
}

# Invariante incondicional: una fila por (sample_id, tax_name). Protege contra
# columnas duplicadas del CSV crudo (read_csv las renombra con sufijo '.1', lo
# que NO colapsa por nombre; aqui sumamos cualquier duplicado real que quede).
# Con el flag apagado este es el unico desduplicado que corre.
q2_long_all <- q2_long_all |>
  group_by(sample_id, tax_name) |>
  summarise(count = sum(count), .groups = "drop")

# Version "solo genero" de QIIME2: excluye prefijos no-genero.
q2_long_genus <- q2_long_all |> filter(!str_detect(tax_name, "^[focdkpr]__"))

# ---- DIAGNOSTICO H1: masa de los taxa no-genero en QIIME2 --------------------
# Responde la pregunta que la auditoria dejo abierta por falta de crudos:
# cuanta masa por muestra cae en los taxa de rango superior (f__/o__/c__/d__).
# Esa masa es exactamente la que la cobertura ASIMETRICA mete en el denominador
# de QIIME2 pero nunca en el numerador. Si es ~0.6-0.8%, explica casi toda la
# brecha 0.999 vs 0.992; si es menor, parte de la brecha son generos no-match.
q2_nongenus_mass <- q2_long_all |>
  group_by(sample_id) |>
  summarise(
    total       = sum(count),
    nongenus    = sum(count[str_detect(tax_name, "^[focdkpr]__")]),
    .groups = "drop"
  ) |>
  mutate(pct_nongenus = nongenus / total)
cat(sprintf(
  ">>> [DIAG H1] Masa no-genero en QIIME2: median = %.4f, IQR [%.4f, %.4f]\n",
  median(q2_nongenus_mass$pct_nongenus),
  quantile(q2_nongenus_mass$pct_nongenus, .25),
  quantile(q2_nongenus_mass$pct_nongenus, .75)))
cat("    (Comparar contra la brecha de cobertura asimetrica QIIME2 ~= 1 - 0.992 = 0.008)\n")
dir.create(file.path(DIR_OUT, "tablas"), recursive = TRUE, showWarnings = FALSE)
write_csv(q2_nongenus_mass,
          file.path(DIR_OUT, "tablas", "diag_h1_masa_nongenus_qiime2.csv"))

cat("  Muestras QIIME2: ", n_distinct(q2_long_all$sample_id), "\n")
cat("  [genus]    taxa QIIME2: ", n_distinct(q2_long_genus$tax_name), "\n")
cat("  [all_taxa] taxa QIIME2: ", n_distinct(q2_long_all$tax_name), "\n\n")

# Plantilla de mapeo curado (componentes MaLiAmPi a sumar bajo un nombre QIIME2).
# build_curated_map() activara solo las entradas con componentes presentes.
# Escherichia-Shigella estaba en el script original -> siempre presente.
# Fannyhessea<-Atopobium es [CURACION EXTENDIDA] -> solo si el flag esta activo.
curated_template <- list(
  "Escherichia-Shigella" = c("Escherichia", "Shigella")
)
if (CURACION_EXTENDIDA) {
  curated_template[["Fannyhessea"]] <- c("Fannyhessea", "Atopobium")
}

# ==============================================================================
# 5. run_track(): TODO el analisis 6-13 para un par (mal_long, q2_long)
# ==============================================================================
# Inputs:
#   mal_long, q2_long : tibbles long con columnas sample_id, tax_name, count.
#   curated_template  : plantilla de mapeo (se filtra a componentes presentes).
#   etiqueta          : "genus" | "all_taxa" (subcarpeta + titulos).
# Devuelve una lista con todos los objetos/resumenes necesarios para el reporte.
run_track <- function(mal_long, q2_long, curated_template, etiqueta) {
  
  cat("\n##############################################################\n")
  cat("### TRACK: ", etiqueta, "\n")
  cat("##############################################################\n")
  
  dir_tablas  <- file.path(DIR_OUT, "tablas",  etiqueta)
  dir_figuras <- file.path(DIR_OUT, "figuras", etiqueta)
  dir.create(dir_tablas,  recursive = TRUE, showWarnings = FALSE)
  dir.create(dir_figuras, recursive = TRUE, showWarnings = FALSE)
  
  # ---- 5.1 Mapeo taxonomico --------------------------------------------------
  mal_taxa <- unique(mal_long$tax_name)
  q2_taxa  <- unique(q2_long$tax_name)
  
  curated_map  <- build_curated_map(curated_template, mal_taxa, etiqueta)
  direct_match <- intersect(q2_taxa, mal_taxa)
  direct_match <- setdiff(direct_match, names(curated_map))
  
  q2_in_map    <- union(direct_match, names(curated_map))
  q2_unmapped  <- setdiff(q2_taxa, q2_in_map)
  mal_unmapped <- setdiff(mal_taxa, unlist(c(direct_match, curated_map)))
  
  cat("  QIIME2 taxa totales:            ", length(q2_taxa), "\n")
  cat("  QIIME2 con match (incl. curado): ", length(q2_in_map), "\n")
  cat("  QIIME2 sin match:               ", length(q2_unmapped), "\n")
  cat("  MaLiAmPi taxa totales:          ", length(mal_taxa), "\n")
  cat("  MaLiAmPi sin match:             ", length(mal_unmapped), "\n")
  
  write_lines(sort(q2_unmapped),  file.path(dir_tablas, "qiime2_taxa_sin_match.txt"))
  write_lines(sort(mal_unmapped), file.path(dir_tablas, "maliampi_taxa_sin_match.txt"))
  
  # ---- 5.2 Aplicar mapeo y construir matrices paired -------------------------
  # MaLiAmPi: re-etiquetar componentes curados al nombre QIIME2 unificado.
  mal_long_unified <- mal_long |>
    filter(tax_name %in% c(direct_match, unlist(curated_map))) |>
    mutate(tax_unified = tax_name)
  for (q_name in names(curated_map)) {
    mal_long_unified <- mal_long_unified |>
      mutate(tax_unified = if_else(tax_name %in% curated_map[[q_name]],
                                   q_name, tax_unified))
  }
  mal_agg <- mal_long_unified |>
    group_by(sample_id, tax_unified) |>
    summarise(count = sum(count), .groups = "drop") |>
    rename(tax_name = tax_unified)
  
  q2_agg <- q2_long |> filter(tax_name %in% q2_in_map)
  
  shared_samples <- intersect(unique(mal_agg$sample_id), unique(q2_agg$sample_id))
  shared_samples <- sort(shared_samples)               # orden canonico estable
  shared_taxa    <- q2_in_map
  cat("  Muestras compartidas: ", length(shared_samples),
      " | taxa compartidos: ", length(shared_taxa), "\n")
  
  mat_mal_abs <- to_wide_counts(mal_agg, shared_samples, shared_taxa)
  mat_q2_abs  <- to_wide_counts(q2_agg,  shared_samples, shared_taxa)
  
  # Alinear estrictamente filas y columnas por nombre (defensivo).
  common_taxa <- intersect(colnames(mat_mal_abs), colnames(mat_q2_abs))
  mat_mal_abs <- mat_mal_abs[shared_samples, common_taxa, drop = FALSE]
  mat_q2_abs  <- mat_q2_abs[shared_samples, common_taxa, drop = FALSE]
  stopifnot(all(rownames(mat_mal_abs) == rownames(mat_q2_abs)))
  stopifnot(all(colnames(mat_mal_abs) == colnames(mat_q2_abs)))
  
  # ---- 5.3 Cobertura de la interseccion (asimetrica Y simetrica) -------------
  # Denominador ASIMETRICO: masa total del pipeline tal como entra (universo
  # completo de mal_long / q2_long). Replica el calculo original.
  mal_total_asym <- mal_long |>
    filter(sample_id %in% shared_samples) |>
    group_by(sample_id) |>
    summarise(total = sum(count), .groups = "drop")
  q2_total_asym <- q2_long |>
    filter(sample_id %in% shared_samples) |>
    group_by(sample_id) |>
    summarise(total = sum(count), .groups = "drop")
  
  # Denominador SIMETRICO: cada pipeline normalizado SOLO sobre los taxa de su
  # propio universo que comparten nivel taxonomico con el numerador.
  #   - MaLiAmPi: en track genus su universo YA es solo-genero (=> simetrico==asym).
  #               en track all_taxa su universo son todos los taxa (=> idem q2).
  #   - QIIME2 (genus): excluir prefijos no-genero del denominador.
  #     QIIME2 (all_taxa): universo completo (no se excluye nada => idem asym).
  if (etiqueta == "genus") {
    q2_long_sym <- q2_long |> filter(!str_detect(tax_name, "^[focdkpr]__"))
  } else {
    q2_long_sym <- q2_long
  }
  mal_long_sym <- mal_long   # ya es el universo correcto del nivel del track
  mal_total_sym <- mal_long_sym |>
    filter(sample_id %in% shared_samples) |>
    group_by(sample_id) |>
    summarise(total = sum(count), .groups = "drop")
  q2_total_sym <- q2_long_sym |>
    filter(sample_id %in% shared_samples) |>
    group_by(sample_id) |>
    summarise(total = sum(count), .groups = "drop")
  
  shared_mal <- rowSums(mat_mal_abs)
  shared_q2  <- rowSums(mat_q2_abs)
  
  idx <- function(tbl, ids) tbl$total[match(ids, tbl$sample_id)]
  coverage_df <- tibble(
    sample_id   = shared_samples,
    shared_mal  = shared_mal[shared_samples],
    shared_q2   = shared_q2[shared_samples],
    total_mal_asym = idx(mal_total_asym, shared_samples),
    total_q2_asym  = idx(q2_total_asym,  shared_samples),
    total_mal_sym  = idx(mal_total_sym,  shared_samples),
    total_q2_sym   = idx(q2_total_sym,   shared_samples)
  ) |>
    mutate(
      pct_mal_asym = shared_mal / total_mal_asym,
      pct_q2_asym  = shared_q2  / total_q2_asym,
      pct_mal_sym  = shared_mal / total_mal_sym,
      pct_q2_sym   = shared_q2  / total_q2_sym
    )
  
  # Chequeos de cordura: nada fuera de [0,1], sin NA por nombres faltantes.
  stopifnot(all(!is.na(coverage_df$pct_mal_asym)),
            all(!is.na(coverage_df$pct_q2_asym)),
            all(coverage_df$pct_q2_sym  <= 1 + 1e-9),
            all(coverage_df$pct_mal_sym <= 1 + 1e-9))
  
  med_iqr <- function(x) sprintf("median = %.3f, IQR [%.3f, %.3f]",
                                 median(x), quantile(x, .25), quantile(x, .75))
  cat("  Cobertura ASIMETRICA  MaLiAmPi: ", med_iqr(coverage_df$pct_mal_asym), "\n")
  cat("  Cobertura ASIMETRICA  QIIME2:   ", med_iqr(coverage_df$pct_q2_asym), "\n")
  cat("  Cobertura SIMETRICA   MaLiAmPi: ", med_iqr(coverage_df$pct_mal_sym), "\n")
  cat("  Cobertura SIMETRICA   QIIME2:   ", med_iqr(coverage_df$pct_q2_sym), "\n")
  
  write_csv(coverage_df, file.path(dir_tablas, "cobertura_interseccion.csv"))
  
  # ---- 5.4 Relativas ---------------------------------------------------------
  # Para Spearman per-taxon usamos relativas sobre la masa COMPLETA del pipeline
  # (representacion honesta de cada pipeline). Usamos el denominador ASIMETRICO
  # aqui a proposito: es la masa real total del pipeline, no la recortada.
  sweep_by <- function(mat, totals_tbl) {
    d <- totals_tbl$total[match(rownames(mat), totals_tbl$sample_id)]
    sweep(mat, 1, d, "/")
  }
  mat_mal_rel <- sweep_by(mat_mal_abs, mal_total_asym)
  mat_q2_rel  <- sweep_by(mat_q2_abs,  q2_total_asym)
  
  # Relativas restringidas a la interseccion (suman 1 por fila): BC, Jaccard, Mantel.
  mat_mal_rel_within <- sweep(mat_mal_abs, 1, rowSums(mat_mal_abs), "/")
  mat_q2_rel_within  <- sweep(mat_q2_abs,  1, rowSums(mat_q2_abs),  "/")
  
  # ---- 5.5 Metrica A: Spearman per-taxon -------------------------------------
  per_taxon <- map_df(common_taxa, function(tx) {
    v_mal <- mat_mal_rel[, tx]; v_q2 <- mat_q2_rel[, tx]
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
  write_csv(per_taxon, file.path(dir_tablas, "spearman_per_taxon.csv"))
  
  # ---- 5.6 Metrica B: Top-K Jaccard per-sample -------------------------------
  topk_df <- tibble(
    sample_id = rownames(mat_mal_rel_within),
    j_top5  = map_dbl(seq_len(nrow(mat_mal_rel_within)),
                      ~ topk_jaccard(mat_mal_rel_within[.x, ], mat_q2_rel_within[.x, ], 5)),
    j_top10 = map_dbl(seq_len(nrow(mat_mal_rel_within)),
                      ~ topk_jaccard(mat_mal_rel_within[.x, ], mat_q2_rel_within[.x, ], 10))
  )
  write_csv(topk_df, file.path(dir_tablas, "topk_jaccard_per_sample.csv"))
  
  # ---- 5.7 Metrica C: Bray-Curtis per-sample (paired) ------------------------
  bc_paired <- map_dbl(seq_len(nrow(mat_mal_rel_within)), function(i) {
    v1 <- mat_mal_rel_within[i, ]; v2 <- mat_q2_rel_within[i, ]
    sum(abs(v1 - v2)) / sum(v1 + v2)
  })
  bc_df <- tibble(sample_id = rownames(mat_mal_rel_within), bray_curtis = bc_paired)
  write_csv(bc_df, file.path(dir_tablas, "bray_curtis_per_sample.csv"))
  
  # ---- 5.8 Metricas D + E: Mantel + Procrustes -------------------------------
  d_mal <- vegdist(mat_mal_rel_within, method = "bray")
  d_q2  <- vegdist(mat_q2_rel_within,  method = "bray")
  set.seed(42)
  mantel_res <- mantel(d_mal, d_q2, method = "spearman", permutations = 999)
  
  pcoa_mal <- cmdscale(d_mal, k = 5, eig = TRUE)
  pcoa_q2  <- cmdscale(d_q2,  k = 5, eig = TRUE)
  proc_res  <- procrustes(pcoa_mal$points, pcoa_q2$points, symmetric = TRUE)
  proc_test <- protest(pcoa_mal$points, pcoa_q2$points,
                       permutations = 999, symmetric = TRUE)
  
  # ---- 5.9 Figuras -----------------------------------------------------------
  ttl <- function(s) paste0(s, "  [", etiqueta, "]")
  
  p_rho_hist <- per_taxon |> filter(!is.na(rho)) |>
    ggplot(aes(x = rho)) +
    geom_histogram(bins = 30, fill = "steelblue", color = "white") +
    geom_vline(xintercept = c(0.3, 0.7), linetype = "dashed", color = "grey40") +
    labs(x = "Spearman rho (per taxon)", y = "Numero de taxa",
         title = ttl("Concordancia per-taxon"),
         subtitle = sprintf("n = %d taxa compartidos", sum(!is.na(per_taxon$rho)))) +
    theme_minimal(base_size = 11)
  
  p_rho_prev <- per_taxon |> filter(!is.na(rho)) |>
    mutate(prev_mean = (prev_mal + prev_q2)/2, abund_mean = (mean_mal + mean_q2)/2) |>
    ggplot(aes(x = prev_mean, y = rho, size = abund_mean, label = taxon)) +
    geom_point(alpha = 0.6, color = "steelblue") +
    geom_text_repel(data = . %>% filter(rho < 0.3 | prev_mean > 0.4),
                    size = 2.7, max.overlaps = 25) +
    geom_hline(yintercept = c(0.3, 0.7), linetype = "dashed", color = "grey40") +
    scale_x_continuous(labels = scales::percent_format(accuracy = 1)) +
    scale_size_continuous(name = "Abundancia\nrelativa media",
                          labels = scales::percent_format(accuracy = 0.1)) +
    labs(x = "Prevalencia media", y = "Spearman rho", title = ttl("rho vs prevalencia")) +
    theme_minimal(base_size = 11)
  
  ggsave(file.path(dir_figuras, "fig01_spearman_per_taxon.png"),
         p_rho_hist + p_rho_prev + plot_layout(widths = c(1, 1.4)),
         width = 12, height = 5, dpi = 150)
  
  # Cobertura: graficamos la version SIMETRICA (la metodologicamente correcta).
  p_cov <- coverage_df |>
    select(sample_id, pct_mal_sym, pct_q2_sym) |>
    pivot_longer(c(pct_mal_sym, pct_q2_sym), names_to = "pipeline", values_to = "pct") |>
    mutate(pipeline = recode(pipeline, pct_mal_sym = "MaLiAmPi", pct_q2_sym = "QIIME2")) |>
    ggplot(aes(x = pipeline, y = pct, fill = pipeline)) +
    geom_violin(alpha = 0.7) +
    geom_boxplot(width = 0.15, outlier.shape = NA, alpha = 0.6) +
    geom_jitter(width = 0.05, size = 0.6, alpha = 0.5) +
    scale_y_continuous(labels = scales::percent_format(accuracy = 1), limits = c(0, 1)) +
    scale_fill_brewer(palette = "Set2", guide = "none") +
    labs(x = NULL, y = "Fraccion de masa por muestra en taxa compartidos (simetrico)",
         title = ttl("Cobertura de la interseccion")) +
    theme_minimal(base_size = 11)
  ggsave(file.path(dir_figuras, "fig02_cobertura_interseccion.png"),
         p_cov, width = 6, height = 5, dpi = 150)
  
  topk_long <- topk_df |>
    pivot_longer(c(j_top5, j_top10), names_to = "k", values_to = "jaccard") |>
    mutate(k = recode(k, j_top5 = "Top-5", j_top10 = "Top-10"))
  p_topk <- ggplot(topk_long, aes(x = k, y = jaccard, fill = k)) +
    geom_violin(alpha = 0.7) + geom_boxplot(width = 0.15, outlier.shape = NA, alpha = 0.6) +
    geom_jitter(width = 0.05, size = 0.6, alpha = 0.5) +
    scale_fill_brewer(palette = "Set1", guide = "none") + ylim(0, 1) +
    labs(x = NULL, y = "Jaccard top-K", title = ttl("Concordancia top taxa")) +
    theme_minimal(base_size = 11)
  p_bc <- ggplot(bc_df, aes(x = "", y = bray_curtis)) +
    geom_violin(fill = "darkorange", alpha = 0.7) +
    geom_boxplot(width = 0.15, outlier.shape = NA, alpha = 0.6) +
    geom_jitter(width = 0.05, size = 0.6, alpha = 0.5) + ylim(0, 1) +
    labs(x = "Bray-Curtis paired", y = "Distancia BC", title = ttl("BC paired")) +
    theme_minimal(base_size = 11)
  ggsave(file.path(dir_figuras, "fig03_per_sample.png"),
         p_topk + p_bc + plot_layout(widths = c(1.2, 1)), width = 11, height = 5, dpi = 150)
  
  proc_plot_df <- tibble(
    sample_id = rownames(mat_mal_rel_within),
    x_mal = pcoa_mal$points[, 1], y_mal = pcoa_mal$points[, 2],
    x_q2  = proc_res$Yrot[, 1],   y_q2  = proc_res$Yrot[, 2]
  )
  p_proc <- ggplot(proc_plot_df) +
    geom_segment(aes(x = x_mal, y = y_mal, xend = x_q2, yend = y_q2),
                 color = "grey60", alpha = 0.6) +
    geom_point(aes(x = x_mal, y = y_mal), color = "steelblue",  size = 2, alpha = 0.7) +
    geom_point(aes(x = x_q2,  y = y_q2),  color = "darkorange", size = 2, alpha = 0.7) +
    labs(x = "PCoA1", y = "PCoA2", title = ttl("Procrustes: MaLiAmPi (azul) vs QIIME2 (naranja)"),
         subtitle = sprintf("M2 = %.3f, correlacion = %.3f, p = %.3g",
                            proc_test$ss, proc_test$t0, proc_test$signif)) +
    theme_minimal(base_size = 11)
  ggsave(file.path(dir_figuras, "fig04_procrustes_pcoa.png"),
         p_proc, width = 7, height = 6, dpi = 150)
  
  # ---- 5.10 Devolver resumenes para el reporte -------------------------------
  list(
    etiqueta = etiqueta,
    n_taxa_mal = length(mal_taxa), n_taxa_q2 = length(q2_taxa),
    n_shared_samples = length(shared_samples), n_shared_taxa = length(common_taxa),
    n_direct = length(direct_match), n_curated = length(curated_map),
    coverage_df = coverage_df, per_taxon = per_taxon, topk_df = topk_df,
    bc_paired = bc_paired, mantel_res = mantel_res, proc_test = proc_test
  )
}

# ==============================================================================
# 6. Correr ambos tracks
# ==============================================================================
res_genus <- run_track(mal_long_genus, q2_long_genus, curated_template, "genus")
res_all   <- run_track(mal_long_all,   q2_long_all,   curated_template, "all_taxa")

# ==============================================================================
# 7. Reporte final (secciones separadas por track)
# ==============================================================================
cat("\n>>> Escribiendo reporte...\n")

bloque_track <- function(r) {
  cov <- r$coverage_df
  mi  <- function(x) sprintf("median = %.3f, IQR [%.3f, %.3f]",
                             median(x), quantile(x, .25), quantile(x, .75))
  c(
    sprintf("- Taxa MaLiAmPi: %d | Taxa QIIME2: %d", r$n_taxa_mal, r$n_taxa_q2),
    sprintf("- Muestras compartidas: %d | Taxa compartidos: %d (directo %d; curado %d)",
            r$n_shared_samples, r$n_shared_taxa, r$n_direct, r$n_curated),
    "",
    "### Cobertura de la interseccion",
    sprintf("- ASIMETRICA  MaLiAmPi: %s", mi(cov$pct_mal_asym)),
    sprintf("- ASIMETRICA  QIIME2:   %s", mi(cov$pct_q2_asym)),
    sprintf("- SIMETRICA   MaLiAmPi: %s", mi(cov$pct_mal_sym)),
    sprintf("- SIMETRICA   QIIME2:   %s", mi(cov$pct_q2_sym)),
    "",
    "### Concordancia per-taxon (Spearman)",
    sprintf("- median rho = %.3f, IQR [%.3f, %.3f] (n = %d evaluables)",
            median(r$per_taxon$rho, na.rm = TRUE),
            quantile(r$per_taxon$rho, .25, na.rm = TRUE),
            quantile(r$per_taxon$rho, .75, na.rm = TRUE),
            sum(!is.na(r$per_taxon$rho))),
    sprintf("- rho > 0.7: %d | rho < 0.3: %d",
            sum(r$per_taxon$rho > 0.7, na.rm = TRUE),
            sum(r$per_taxon$rho < 0.3, na.rm = TRUE)),
    "",
    "### Concordancia per-sample",
    sprintf("- Jaccard top-5:  %s", mi(r$topk_df$j_top5)),
    sprintf("- Jaccard top-10: %s", mi(r$topk_df$j_top10)),
    sprintf("- Bray-Curtis paired: %s", mi(r$bc_paired)),
    "",
    "### Estructura comunitaria (inter-muestra)",
    sprintf("- Mantel r (Spearman): %.3f, p = %.3g", r$mantel_res$statistic, r$mantel_res$signif),
    sprintf("- Procrustes M2: %.3f, correlacion = %.3f, p = %.3g",
            r$proc_test$ss, r$proc_test$t0, r$proc_test$signif),
    ""
  )
}

reporte <- c(
  "# Gate de concordancia QIIME2/DADA2 vs MaLiAmPi - Reporte (v3)",
  paste0("Fecha: ", Sys.Date()),
  "",
  paste0("CURACION_EXTENDIDA = ", CURACION_EXTENDIDA,
         ". Conteos QIIME2 re-anclados al crudo por el mapa canonico; filas corregidas: ",
         length(ajenas), if (length(ajenas)) paste0(" (", paste(ajenas, collapse = ", "), ")") else "", "."),
  "",
  "Cobertura reportada en dos variantes: ASIMETRICA (denominador = masa total",
  "del pipeline) y SIMETRICA (cada pipeline normalizado solo sobre su universo",
  "del mismo nivel taxonomico que participa del match). Ver auditoria.",
  "",
  "## Generos unicamente",
  bloque_track(res_genus),
  "## Todos los taxa",
  bloque_track(res_all),
  "## Outputs",
  "- tablas/<track>/ y figuras/<track>/ con track in {genus, all_taxa}.",
  "- Mismos nombres de archivo en ambos tracks."
)
writeLines(reporte, file.path(DIR_OUT, "reporte.md"))

cat("\n=== Listo. Outputs en:", DIR_OUT, "===\n")