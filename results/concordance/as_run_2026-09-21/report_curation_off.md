# Gate de concordancia QIIME2/DADA2 vs MaLiAmPi - Reporte (v3)
Fecha: 2026-09-21

CURACION_EXTENDIDA = FALSE. Conteos QIIME2 re-anclados al crudo por el mapa canonico; filas corregidas: 4 (Au52, Au203, Au197, Au179).

Cobertura reportada en dos variantes: ASIMETRICA (denominador = masa total
del pipeline) y SIMETRICA (cada pipeline normalizado solo sobre su universo
del mismo nivel taxonomico que participa del match). Ver auditoria.

## Generos unicamente
- Taxa MaLiAmPi: 314 | Taxa QIIME2: 80
- Muestras compartidas: 110 | Taxa compartidos: 61 (directo 60; curado 1)

### Cobertura de la interseccion
- ASIMETRICA  MaLiAmPi: median = 0.964, IQR [0.923, 0.981]
- ASIMETRICA  QIIME2:   median = 0.990, IQR [0.976, 0.995]
- SIMETRICA   MaLiAmPi: median = 0.964, IQR [0.923, 0.981]
- SIMETRICA   QIIME2:   median = 0.990, IQR [0.976, 0.995]

### Concordancia per-taxon (Spearman)
- median rho = 0.544, IQR [0.401, 0.711] (n = 46 evaluables)
- rho > 0.7: 14 | rho < 0.3: 8

### Concordancia per-sample
- Jaccard top-5:  median = 0.667, IQR [0.429, 0.667]
- Jaccard top-10: median = 0.538, IQR [0.429, 0.667]
- Bray-Curtis paired: median = 0.062, IQR [0.038, 0.116]

### Estructura comunitaria (inter-muestra)
- Mantel r (Spearman): 0.973, p = 0.001
- Procrustes M2: 0.081, correlacion = 0.959, p = 0.001

## Todos los taxa
- Taxa MaLiAmPi: 438 | Taxa QIIME2: 97
- Muestras compartidas: 110 | Taxa compartidos: 61 (directo 60; curado 1)

### Cobertura de la interseccion
- ASIMETRICA  MaLiAmPi: median = 0.923, IQR [0.817, 0.952]
- ASIMETRICA  QIIME2:   median = 0.985, IQR [0.970, 0.993]
- SIMETRICA   MaLiAmPi: median = 0.923, IQR [0.817, 0.952]
- SIMETRICA   QIIME2:   median = 0.985, IQR [0.970, 0.993]

### Concordancia per-taxon (Spearman)
- median rho = 0.545, IQR [0.405, 0.708] (n = 46 evaluables)
- rho > 0.7: 14 | rho < 0.3: 8

### Concordancia per-sample
- Jaccard top-5:  median = 0.667, IQR [0.429, 0.667]
- Jaccard top-10: median = 0.538, IQR [0.429, 0.667]
- Bray-Curtis paired: median = 0.062, IQR [0.038, 0.116]

### Estructura comunitaria (inter-muestra)
- Mantel r (Spearman): 0.973, p = 0.001
- Procrustes M2: 0.081, correlacion = 0.959, p = 0.001

## Outputs
- tablas/<track>/ y figuras/<track>/ con track in {genus, all_taxa}.
- Mismos nombres de archivo en ambos tracks.
