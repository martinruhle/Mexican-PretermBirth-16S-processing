# Gate de concordancia QIIME2/DADA2 vs MaLiAmPi - Reporte (v3)
Fecha: 2026-09-21

CURACION_EXTENDIDA = TRUE. Conteos QIIME2 re-anclados al crudo por el mapa canonico; filas corregidas: 4 (Au52, Au203, Au197, Au179).

Cobertura reportada en dos variantes: ASIMETRICA (denominador = masa total
del pipeline) y SIMETRICA (cada pipeline normalizado solo sobre su universo
del mismo nivel taxonomico que participa del match). Ver auditoria.

## Generos unicamente
- Taxa MaLiAmPi: 314 | Taxa QIIME2: 77
- Muestras compartidas: 110 | Taxa compartidos: 65 (directo 63; curado 2)

### Cobertura de la interseccion
- ASIMETRICA  MaLiAmPi: median = 0.999, IQR [0.997, 1.000]
- ASIMETRICA  QIIME2:   median = 0.996, IQR [0.993, 0.999]
- SIMETRICA   MaLiAmPi: median = 0.999, IQR [0.997, 1.000]
- SIMETRICA   QIIME2:   median = 0.996, IQR [0.993, 0.999]

### Concordancia per-taxon (Spearman)
- median rho = 0.585, IQR [0.418, 0.711] (n = 50 evaluables)
- rho > 0.7: 15 | rho < 0.3: 8

### Concordancia per-sample
- Jaccard top-5:  median = 0.667, IQR [0.429, 0.667]
- Jaccard top-10: median = 0.538, IQR [0.429, 0.667]
- Bray-Curtis paired: median = 0.099, IQR [0.058, 0.156]

### Estructura comunitaria (inter-muestra)
- Mantel r (Spearman): 0.958, p = 0.001
- Procrustes M2: 0.144, correlacion = 0.925, p = 0.001

## Todos los taxa
- Taxa MaLiAmPi: 437 | Taxa QIIME2: 94
- Muestras compartidas: 110 | Taxa compartidos: 65 (directo 63; curado 2)

### Cobertura de la interseccion
- ASIMETRICA  MaLiAmPi: median = 0.974, IQR [0.948, 0.987]
- ASIMETRICA  QIIME2:   median = 0.992, IQR [0.985, 0.996]
- SIMETRICA   MaLiAmPi: median = 0.974, IQR [0.948, 0.987]
- SIMETRICA   QIIME2:   median = 0.992, IQR [0.985, 0.996]

### Concordancia per-taxon (Spearman)
- median rho = 0.582, IQR [0.419, 0.708] (n = 50 evaluables)
- rho > 0.7: 15 | rho < 0.3: 8

### Concordancia per-sample
- Jaccard top-5:  median = 0.667, IQR [0.429, 0.667]
- Jaccard top-10: median = 0.538, IQR [0.429, 0.667]
- Bray-Curtis paired: median = 0.099, IQR [0.058, 0.156]

### Estructura comunitaria (inter-muestra)
- Mantel r (Spearman): 0.958, p = 0.001
- Procrustes M2: 0.144, correlacion = 0.925, p = 0.001

## Outputs
- tablas/<track>/ y figuras/<track>/ con track in {genus, all_taxa}.
- Mismos nombres de archivo en ambos tracks.
