# Gate de concordancia QIIME2/DADA2 vs MaLiAmPi - Reporte (v2)
Fecha: 2026-05-22

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
- median rho = 0.506, IQR [0.373, 0.701] (n = 46 evaluables)
- rho > 0.7: 12 | rho < 0.3: 9

### Concordancia per-sample
- Jaccard top-5:  median = 0.667, IQR [0.429, 0.667]
- Jaccard top-10: median = 0.538, IQR [0.429, 0.667]
- Bray-Curtis paired: median = 0.070, IQR [0.039, 0.123]

### Estructura comunitaria (inter-muestra)
- Mantel r (Spearman): 0.951, p = 0.001
- Procrustes M2: 0.092, correlacion = 0.953, p = 0.001

## Todos los taxa
- Taxa MaLiAmPi: 438 | Taxa QIIME2: 97
- Muestras compartidas: 110 | Taxa compartidos: 61 (directo 60; curado 1)

### Cobertura de la interseccion
- ASIMETRICA  MaLiAmPi: median = 0.923, IQR [0.817, 0.952]
- ASIMETRICA  QIIME2:   median = 0.985, IQR [0.970, 0.993]
- SIMETRICA   MaLiAmPi: median = 0.923, IQR [0.817, 0.952]
- SIMETRICA   QIIME2:   median = 0.985, IQR [0.970, 0.993]

### Concordancia per-taxon (Spearman)
- median rho = 0.511, IQR [0.378, 0.700] (n = 46 evaluables)
- rho > 0.7: 12 | rho < 0.3: 9

### Concordancia per-sample
- Jaccard top-5:  median = 0.667, IQR [0.429, 0.667]
- Jaccard top-10: median = 0.538, IQR [0.429, 0.667]
- Bray-Curtis paired: median = 0.070, IQR [0.039, 0.123]

### Estructura comunitaria (inter-muestra)
- Mantel r (Spearman): 0.951, p = 0.001
- Procrustes M2: 0.092, correlacion = 0.953, p = 0.001

## Outputs
- tablas/<track>/ y figuras/<track>/ con track in {genus, all_taxa}.
- Mismos nombres de archivo en ambos tracks.
