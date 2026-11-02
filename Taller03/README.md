# Taller 3 – Agrupamiento K-Means y Jerárquico Aglomerativo

**Pontificia Universidad Javeriana** · Maestría en Inteligencia Artificial · Aprendizaje de Máquina · 202630

## Integrantes

- Salomón Avila
- Carlos Caicedo

## Archivos entregados

| Archivo | Descripción |
|---|---|
| `README.md` | Este archivo. Integrantes y descripción de los archivos entregados. |
| `Taller03 Aprendizaje de máquina.pdf` | Informe escrito en formato IEEE (IEEE Transactions on Artificial Intelligence). |
| `code/TALLER_3_Agrupamiento_K_Means_y_Jerárquico_Aglomerativo.ipynb` | Notebook de Python con todo el código del taller, ejecutado y con sus salidas. |

### Informe

Incluye introducción, marco teórico, metodología, experimentación, resultados y conclusiones del Punto 1 para K-Means, Clustering Jerárquico Aglomerativo y HDBSCAN (bono), además de las conclusiones generales del taller (¿Qué funcionó?, ¿Qué no funcionó?, ¿Qué aprendimos?).

### Notebook

- **Preparación de datos:** carga del dataset *Drug Consumption (Quantified)* desde el repositorio UCI (paquete `ucimlrepo`, `id=373`), desnormalización de las variables sociodemográficas y binarización del consumo de las 19 sustancias (0 = no consumidor, 1 = consumidor).
- **Exploración:** proyección PCA en 2D.
- **K-Means:** método del codo, coeficiente de silueta para K = 2, 3 y 4, y partición final con K = 2.
- **Clustering Jerárquico Aglomerativo:** comparación de los enlaces Ward, complete, average y single; dendrograma con el corte que produce K = 2; partición final con enlace de Ward y comparación con K-Means.
- **HDBSCAN (bono):** sensibilidad a `min_cluster_size`, estimación de densidad con la *core distance*, árbol de expansión mínima (MST) y métrica DBCV.
- **Análisis de cada método:** diagramas de caja de los rasgos psicométricos, perfil promedio por clúster, tablas cruzadas sociodemográficas, prevalencia de consumo por clúster y pruebas Chi-cuadrado de independencia.

## Ejecución

Requiere Python 3 con las siguientes librerías:

```
ucimlrepo pandas numpy matplotlib seaborn scikit-learn scipy hdbscan jinja2
```

`jinja2` se usa para el estilo de las tablas. El dataset se descarga automáticamente desde el repositorio UCI, por lo que se necesita conexión a internet. Las celdas deben ejecutarse en orden.
