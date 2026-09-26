# ==============================================================================
# Verificacion muestra por muestra del apareo MaLiAmPi <-> QIIME2 (2026-09-21)
#
# Pregunta: el gate de concordancia del 2026-05-22 (gate_qiime2_maliampi_v2.R)
# comparo, para cada specimen Au###, el perfil MaLiAmPi y el perfil QIIME2 DE LA
# MISMA muestra?
#
# Cuatro pruebas, ninguna depende de una etiqueta cargada a mano:
#   1. Etiqueta: index_original de la tabla QIIME2 del gate vs el mapa canonico.
#   2. Huella de conteos: cada fila de esa tabla vs el crudo de QIIME2
#      (level-6_vag138.xlsx, filas identificadas por el sample-id de QIIME2).
#   3. Profundidad: total MaLiAmPi por Au vs lecturas del QC del secuenciador
#      y vs conteos QIIME2 del mismo Au.
#   4. Sufijo _S## de MaLiAmPi vs el orden de la hoja de muestras (QC).
# Ademas: metadata_qiime.csv vs el mapa canonico (solo conteos agregados).
#
# La salida NO imprime participante, visita ni desenlace: va a un repo publico.
# Kept as run: rutas absolutas incluidas.
# ==============================================================================
suppressPackageStartupMessages({ library(readxl); library(pdftools) })
D <- "C:/Users/marti/Documents/Datos_mexicanos/"
PATH_MAPA     <- paste0(D, "mapa_muestras_2026-09-20.csv")
PATH_CRUDO    <- paste0(D, "level-6_vag138.xlsx")
PATH_GATE_Q2  <- paste0(D, "genus_rel_filtered_conc_2026-03-06_abs.csv")
PATH_MALIAMPI <- paste0(D, "MaLiAmPi/archivos_extra/salida_analisis/classify/tables/tallies_wide.genus.csv")
PATH_QCS      <- paste0(D, "QC/QCS_22Jul24_412.pdf")
PATH_MDQ      <- paste0(D, "metadata_qiime.csv")
say <- function(...) cat(sprintf(...), "\n", sep = "")

say("=== Insumos (SHA-256) ===")
for (p in c(PATH_MAPA, PATH_CRUDO, PATH_GATE_Q2, PATH_MALIAMPI, PATH_QCS, PATH_MDQ))
  say("%s  %s", digest::digest(p, algo = "sha256", file = TRUE), basename(p))

mapa <- read.csv(PATH_MAPA, stringsAsFactors = FALSE)
si   <- mapa$Au[mapa$en_analisis == "si"]
say("\nMapa canonico: %d specimens, %d en analisis; excluidos: %s",
    nrow(mapa), length(si), paste(mapa$Au[mapa$en_analisis != "si"], collapse = ", "))

raw <- as.data.frame(read_excel(PATH_CRUDO, .name_repair = "minimal"))
CNT <- as.matrix(raw[, grepl("__", names(raw))]); storage.mode(CNT) <- "numeric"
rownames(CNT) <- raw$index
q <- read.csv(PATH_GATE_Q2, check.names = FALSE, stringsAsFactors = FALSE)
Q <- as.matrix(q[, 1:ncol(CNT)]); storage.mode(Q) <- "numeric"

# ---- 1. etiqueta -------------------------------------------------------------
au_mapa <- mapa$Au[match(q$index, mapa$index)]
say("\n[1] Etiqueta index_original == Au del mapa canonico (via index): %d / %d",
    sum(au_mapa == q$index_original), nrow(q))

# ---- 2. huella de conteos ----------------------------------------------------
h <- function(m) apply(m, 1, paste, collapse = ",")
hq <- h(Q); hc <- setNames(h(CNT), rownames(CNT))
duenio <- names(hc)[match(hq, hc)]
say("[2] Filas de la tabla del gate identicas a exactamente una muestra del crudo: %d / %d (sin repetir: %s)",
    sum(!is.na(duenio)), nrow(q), !anyDuplicated(duenio))
say("    Filas cuyos conteos son de su propia muestra: %d / %d", sum(duenio == au_mapa), nrow(q))
mal_ap <- which(duenio != au_mapa)
for (i in mal_ap) say("    etiqueta %-6s lleva los conteos de %s", au_mapa[i], duenio[i])
say("    Totales del crudo por Au == mapa$conteos_qiime: %s", all(rowSums(CNT)[mapa$Au] == mapa$conteos_qiime))

# ---- 3. profundidad ----------------------------------------------------------
mal <- read.csv(PATH_MALIAMPI, check.names = FALSE)
tot <- colSums(mal[, -(1:3)], na.rm = TRUE); names(tot) <- sub("_S\\d+$", "", names(tot))
stopifnot(setequal(names(tot), mapa$Au))
m <- mapa; m$mal <- tot[m$Au]
say("\n[3] Spearman(total MaLiAmPi, lecturas del QC del secuenciador), 111 Au: %.3f",
    cor(m$mal, m$lecturas_crudas, method = "spearman"))
say("    Cociente MaLiAmPi / lecturas crudas: mediana %.2f, rango %.2f-%.2f",
    median(m$mal / m$lecturas_crudas), min(m$mal / m$lecturas_crudas), max(m$mal / m$lecturas_crudas))
en <- m[m$en_analisis == "si", ]
q2_gate <- setNames(rowSums(Q), au_mapa)
say("    Spearman(total MaLiAmPi, conteos QIIME2 del mismo Au), 110: %.4f", cor(en$mal, en$conteos_qiime, method = "spearman"))
say("    Spearman(total MaLiAmPi, conteos QIIME2 tal como los aparejo el gate v2): %.4f",
    cor(en$mal, q2_gate[en$Au], method = "spearman"))

# ---- 4. sufijo _S## ----------------------------------------------------------
L <- unlist(lapply(pdf_text(PATH_QCS), function(p) strsplit(p, "\n")[[1]]))
x <- regmatches(L, regexec("^\\s*(\\d+)\\s+(Au\\d+)\\s+([ACGT]{8}-[ACGT]{8})\\s+([0-9,]+)", L))
s <- do.call(rbind, lapply(x[lengths(x) > 0], function(v) data.frame(n = as.integer(v[2]), Au = v[3])))
cols <- names(mal)[-(1:3)]
S <- setNames(as.integer(sub(".*_S", "", cols)), sub("_S\\d+$", "", cols))
say("\n[4] Columnas MaLiAmPi cuyo _S## == posicion en la hoja de muestras del QC: %d / %d",
    sum(S[s$Au] == s$n), nrow(s))
say("    Au122 en MaLiAmPi: %s", grep("^Au122_", cols, value = TRUE))

# ---- metadata_qiime.csv ------------------------------------------------------
mq <- read.csv(PATH_MDQ, stringsAsFactors = FALSE)
j  <- merge(mapa[mapa$en_analisis == "si", ], mq, by.x = "Au", by.y = "index", suffixes = c(".m", ".q"))
pt <- function(v) v %in% c("Preterm", "Abortion")
say("\n[metadata_qiime.csv] De las %d muestras en analisis:", nrow(j))
say("    (participante, visita) distinto del mapa: %d  [otra participante: %d; misma, otra visita: %d]",
    sum(j$id.m != j$id.q | j$visita.m != j$visita.q), sum(j$id.m != j$id.q),
    sum(j$id.m == j$id.q & j$visita.m != j$visita.q))
say("    desenlace_parto distinto: %d; pretermino (Preterm/Abortion) invertido: %d",
    sum(j$desenlace_parto.m != j$desenlace_parto.q), sum(pt(j$desenlace_parto.m) != pt(j$desenlace_parto.q)))
say("    Incluye a los excluidos por el mapa: %s", paste(intersect(mq$index, mapa$Au[mapa$en_analisis != "si"]), collapse = ", "))
