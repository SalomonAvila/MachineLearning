// =====================================================================
// Taller 3 - Aprendizaje de Máquina
// Formato a dos columnas, igual al del Taller 1 (plantilla IEEEtran)
// =====================================================================

#set document(
  title: "Taller 3: Agrupamiento K-Means, Jerárquico Aglomerativo y HDBSCAN",
  author: ("Salomón Avila", "Carlos Caicedo"),
)

#set page(
  paper: "us-letter",
  margin: (top: 0.75in, bottom: 1in, x: 0.625in),
  columns: 2,
  numbering: "1",
  number-align: center,
)
#set columns(gutter: 0.2in)

#set text(font: ("Nimbus Roman", "Liberation Serif"), size: 10pt, lang: "es")
#set par(justify: true, first-line-indent: (amount: 1em, all: false), leading: 0.52em, spacing: 0.6em)

// ---------- Ecuaciones ----------
#set math.equation(numbering: "(1)", supplement: [Ec.])
#show math.equation: set block(spacing: 0.7em)

// ---------- Encabezados al estilo IEEE ----------
#set heading(numbering: (..n) => {
  let n = n.pos()
  if n.len() == 1 { numbering("I.", ..n) }
  else if n.len() == 2 { numbering("A.", n.at(1)) }
  else { numbering("1)", n.at(2)) }
})
#show heading.where(level: 1): it => block(above: 1.1em, below: 0.7em, width: 100%)[
  #set align(center)
  #set text(size: 10pt, weight: "regular")
  #if it.numbering == none { smallcaps(it.body) } else {
    smallcaps[#counter(heading).display(it.numbering)~~#it.body]
  }
]
#show heading.where(level: 2): it => block(above: 0.9em, below: 0.5em)[
  #set text(size: 10pt, weight: "regular", style: "italic")
  #counter(heading).display(it.numbering)~#it.body
]
#show heading.where(level: 3): it => block(above: 0.8em, below: 0.4em)[
  #set text(size: 10pt, weight: "regular", style: "italic")
  #counter(heading).display(it.numbering)~#it.body:
]

// ---------- Figuras y tablas ----------
#show figure.where(kind: image): set figure(supplement: [Fig.])
#show figure.where(kind: table): set figure(supplement: [Tabla], numbering: "I")
#show figure.where(kind: table): set figure.caption(position: top)
#set figure(gap: 0.5em)
#show figure: set block(spacing: 1em)
#show figure.caption: it => {
  set text(size: 8pt)
  if it.kind == table {
    align(center, smallcaps[Tabla #context it.counter.display(it.numbering) \ #it.body])
  } else {
    set par(justify: true, first-line-indent: 0pt)
    [Fig. #context it.counter.display(it.numbering). #it.body]
  }
}
#set table(stroke: none, inset: (x: 4pt, y: 2.5pt))
#show table: set text(size: 8pt)

#let toprule = table.hline(stroke: 0.8pt)
#let midrule = table.hline(stroke: 0.5pt)
#let bottomrule = table.hline(stroke: 0.8pt)
#let ns(x) = [#x#super[†]]  // marca de resultado no significativo

// =====================================================================
// Título, autores, resumen
// =====================================================================
#place(top + center, float: true, scope: "parent", clearance: 1.6em)[
  #text(size: 22pt)[Taller 3: Agrupamiento K-Means, Jerárquico Aglomerativo y por Densidad (HDBSCAN) sobre el Drug Consumption Dataset]
  #v(0.9em)
  #text(size: 11pt)[Salomón Avila, Carlos Caicedo]
]

#[
  #set text(size: 9pt, weight: "bold")
  #set par(first-line-indent: 0pt)
  #text(style: "italic")[Resumen]---Este documento presenta el desarrollo del Taller 3 del curso de Aprendizaje de Máquina de la Maestría en Inteligencia Artificial. Sobre el conjunto de datos _Drug Consumption (Quantified)_ del UCI Machine Learning Repository se aplican tres familias de agrupamiento no supervisado: K-Means, agrupamiento jerárquico aglomerativo con vínculo de Ward y agrupamiento por densidad con HDBSCAN. Los grupos se construyen únicamente con las variables sociodemográficas y psicométricas, y el consumo de 19 sustancias se usa después para caracterizarlos. K-Means y el método jerárquico encuentran dos perfiles coherentes entre sí: uno joven, masculino, impulsivo y con alta búsqueda de sensaciones, y otro mayor, femenino y con alta responsabilidad. El primero presenta tasas de consumo de sustancias recreativas mucho mayores. HDBSCAN, en cambio, clasifica el 86.6 % de los individuos como ruido y obtiene un DBCV cercano a cero, lo que confirma que los datos forman una única nube continua sin regiones de densidad separadas.
]

#[
  #set text(size: 9pt, weight: "bold")
  #set par(first-line-indent: 0pt)
  #text(style: "italic")[Palabras clave]---Aprendizaje no supervisado, K-Means, coeficiente de silueta, agrupamiento jerárquico, Ward, HDBSCAN, DBCV, Drug Consumption Dataset
]

// =====================================================================
= Introducción
// =====================================================================

El aprendizaje no supervisado busca estructura en los datos sin una variable objetivo que guíe el entrenamiento, por lo que se usa principalmente como herramienta de análisis exploratorio. En este taller se estudia si es posible identificar perfiles de personas a partir de sus rasgos de personalidad y sus características sociodemográficas, y si esos perfiles se asocian con patrones distintos de consumo de sustancias.

Para ello se comparan dos enfoques. El agrupamiento _particional_ (K-Means) divide los datos en $K$ grupos exclusivos, y el agrupamiento _jerárquico_ aglomerativo construye una secuencia anidada de particiones que se representa con un dendrograma. Como tercer enfoque se usa HDBSCAN, un método no paramétrico basado en densidad que no requiere fijar $K$ y que puede dejar puntos sin asignar como ruido.

La elección de las variables que se usan para agrupar no es neutra: según el teorema del patito feo de Watanabe, sin un sesgo que dé más peso a unas características que a otras, cualquier par de objetos es igual de similar. Por eso los grupos se forman solo con las variables de personalidad y sociodemográficas, y el consumo de sustancias se reserva para interpretar los grupos obtenidos.

// =====================================================================
= Marco teórico
// =====================================================================

== K-Means

K-Means es un método particional y exclusivo que busca $K$ centroides $mu_1, dots, mu_K$ que minimicen la suma de distancias cuadradas de cada punto al centroide de su grupo:

$ J = sum_(k=1)^K sum_(x_i in C_k) norm(x_i - mu_k)^2 $ <eq:kmeans>

Encontrar el mínimo global de @eq:kmeans es un problema NP-hard, por lo que se usa un algoritmo iterativo que alterna entre asignar cada punto al centroide más cercano y recalcular cada centroide como la media de sus puntos, hasta que las asignaciones no cambian. Con K-Means++ los centroides iniciales se eligen alejados entre sí, lo que mejora la convergencia. La distancia utilizada es la euclidiana, caso particular ($p = 2$) de la distancia de Minkowski:

$ d(x, y) = (sum_(j=1)^m abs(x_j - y_j)^p)^(1 \/ p) $ <eq:minkowski>

El número de grupos $K$ se elige con el _método del codo_, que busca el punto a partir del cual la inercia (@eq:kmeans) deja de disminuir de forma importante. K-Means es sensible a valores atípicos y tiene dificultades con grupos de distinto tamaño, densidad o forma no esférica.

== Coeficiente de silueta

Para cada punto $i$ se calcula $a(i)$, la distancia promedio a los demás puntos de su grupo, y $b(i)$, la menor distancia promedio a los puntos de otro grupo. La silueta del punto es:

$ s(i) = (b(i) - a(i)) / max{a(i), b(i)} $ <eq:silueta>

El coeficiente global es el promedio de $s(i)$ y toma valores en $[-1, 1]$. Valores cercanos a 1 indican grupos compactos y bien separados, y valores cercanos a 0 indican grupos que se solapan.

== Agrupamiento jerárquico aglomerativo

El método parte de un grupo por cada observación y en cada iteración fusiona los dos grupos más cercanos, hasta formar un único grupo. El resultado es un dendrograma que muestra la partición a distintos niveles de granularidad; cortarlo a una altura dada produce una partición concreta. La distancia entre grupos depende del criterio de vínculo (_complete_, _single_, _average_, _centroid_ o _Ward_). Con el criterio de Ward se fusionan los dos grupos $A$ y $B$ que menos aumentan la suma de distancias cuadradas intra-grupo:

$ Delta(A, B) = (abs(A) abs(B)) / (abs(A) + abs(B)) norm(mu_A - mu_B)^2 $ <eq:ward>

== HDBSCAN

HDBSCAN es una versión jerárquica del agrupamiento por densidad. La _core distance_ de un punto, $"core"_k (x)$, es la distancia a su $k$-ésimo vecino más cercano, con $k$ = `min_samples`, y su inverso puede usarse como una estimación de la densidad local. A partir de ella se define la _mutual reachability distance_:

$ d_"mreach" (a, b) = max{"core"_k (a), "core"_k (b), d(a, b)} $ <eq:mreach>

que aleja entre sí a los puntos de regiones poco densas. Sobre el grafo completo con estas distancias se construye el Árbol de Expansión Mínima (MST); al eliminar sus aristas de mayor a menor peso se obtiene una jerarquía de grupos. Solo se conservan los grupos con al menos `min_cluster_size` puntos, y los puntos que no pertenecen a ninguno se etiquetan como ruido ($-1$).

== Validación basada en densidad (DBCV)

DBCV evalúa cada grupo $C_i$ comparando su conectividad interna (_IntraConnectivity_) con su separación respecto a los demás grupos (_InterSeparation_):

$ V(C_i) = ("Sep"(C_i) - "Intra"(C_i)) / max{"Sep"(C_i), "Intra"(C_i)} $ <eq:dbcv>

El índice global es el promedio de $V(C_i)$ ponderado por el tamaño de cada grupo; toma valores en $[-1, 1]$ y valores altos indican grupos densos y bien separados.

// =====================================================================
= Datos y preparación
// =====================================================================

Se utiliza el conjunto _Drug Consumption (Quantified)_ @uci, con 1885 encuestados. Las variables de agrupamiento son doce: cinco sociodemográficas (`age`, `gender`, `education`, `country`, `ethnicity`) y siete psicométricas: los cinco rasgos de personalidad NEO-FFI-R (neuroticismo `nscore`, extraversión `escore`, apertura `oscore`, amabilidad `ascore` y responsabilidad `cscore`), la impulsividad (`impulsive`, BIS-11) y la búsqueda de sensaciones (`ss`, ImpSS).

El conjunto viene depurado, sin datos faltantes, y ya cuantificado: las variables psicométricas están estandarizadas con _z-score_ y las sociodemográficas están codificadas como valores reales. Por eso no se aplica una estandarización adicional antes de agrupar. Las variables nominales (`gender`, `country` y `ethnicity`) se usan con esta cuantificación de origen y no con codificación one-hot, porque el escalamiento óptimo ya les asigna valores numéricos y one-hot añadiría muchas dimensiones binarias que dominarían la distancia euclidiana. Su peso en la distancia es reducido: por ejemplo, `ethnicity` tiene una desviación estándar de 0.17, frente a cerca de 1 en las variables psicométricas. Para interpretar los resultados se construyó un diccionario que recupera la categoría original de cada valor sociodemográfico. Además, se corrigió el nombre de la columna `impuslive` a `impulsive`.

El consumo de 19 sustancias, registrado originalmente en siete niveles (`CL0` = nunca la ha usado, hasta `CL6` = la usó el último día), se binarizó como 0 si la persona nunca la ha consumido y 1 en cualquier otro caso. Estas variables no participan en el agrupamiento.

#figure(
  image("figuras/pca_distribucion.png", width: 88%),
  caption: [Proyección de las doce variables de agrupamiento en dos componentes principales (PCA).],
) <fig:pca>

Como apoyo visual, los datos se proyectaron en dos dimensiones con PCA (@fig:pca). Se observa una única nube densa, concentrada en el centro y sin separaciones visibles. Al colorear la misma proyección según el consumo de cada sustancia, consumidores y no consumidores aparecen muy superpuestos. Desde esta exploración se anticipa que no hay grupos naturales bien separados.

// =====================================================================
= Agrupamiento con K-Means
// =====================================================================

== Selección de $K$

Se entrenó K-Means (inicialización K-Means++, 10 reinicios, `random_state=42`) para $K = 1, dots, 11$. La curva de inercia (@fig:codo) cae con fuerza entre $K = 1$ y $K = 2$ y luego disminuye de forma cada vez más suave, sin un codo marcado más adelante. Para decidir se calculó el coeficiente de silueta de $K = 2, 3, 4$ (@tab:silueta): $K = 2$ obtiene el valor más alto, por lo que se elige esa partición.

#figure(
  image("figuras/codo_kmeans.png", width: 92%),
  caption: [Método del codo: inercia de K-Means en función de $K$.],
) <fig:codo>

#figure(
  table(
    columns: 3,
    align: (left, center, center),
    toprule,
    [*Método*], [*$K$*], [*Silueta*],
    midrule,
    [K-Means], [2], [*0.1663*],
    [K-Means], [3], [0.1423],
    [K-Means], [4], [0.1099],
    [Jerárquico (Ward)], [2], [0.1253],
    bottomrule,
  ),
  caption: [Coeficiente de silueta por partición],
) <tab:silueta>

El valor de silueta es bajo aun para el mejor $K$, lo que indica que los dos grupos se solapan bastante. Esto es coherente con la nube única de la @fig:pca: K-Means divide una región continua en dos mitades, más que descubrir dos grupos separados.

== Partición obtenida

Con $K = 2$ se obtienen dos grupos de tamaño similar: 955 personas en el clúster 0 y 930 en el clúster 1. En la proyección PCA (@fig:kmeans) la frontera entre ambos es aproximadamente un corte recto sobre la primera componente principal, como corresponde a una asignación por centroide más cercano.

#figure(
  image("figuras/kmeans_pca.png", width: 82%),
  caption: [Partición de K-Means con $K = 2$ sobre la proyección PCA.],
) <fig:kmeans>

== Caracterización de los grupos

La @tab:perfil resume el promedio de cada rasgo psicométrico por grupo y la @fig:box_kmeans muestra sus distribuciones. El clúster 1 tiene impulsividad (0.58) y búsqueda de sensaciones (0.61) altas, mayor apertura y neuroticismo, y menor responsabilidad (-0.51) y amabilidad. El clúster 0 muestra el patrón inverso, con responsabilidad alta (0.50) y baja impulsividad.

#figure(
  placement: top,
  scope: "parent",
  image("figuras/boxplot_kmeans.png", width: 82%),
  caption: [Distribución de los rasgos psicométricos estandarizados en los dos clústeres de K-Means.],
) <fig:box_kmeans>

En lo sociodemográfico, el 53.55 % del clúster 1 tiene entre 18 y 24 años, el 64.30 % son hombres, el 48.39 % reside en Estados Unidos y el 42.80 % tiene estudios universitarios sin título. El clúster 0 tiene una edad más repartida (solo 15.18 % entre 18 y 24 años), el 63.87 % son mujeres, el 79.58 % reside en el Reino Unido y predominan el pregrado (30.89 %) y la maestría (22.09 %). La etnia no diferencia a los grupos: en ambos más del 90 % se identifica como blanco.

#figure(
  placement: top,
  scope: "parent",
  table(
    columns: 9,
    align: (left, center, center, center, center, center, center, center, left),
    toprule,
    [*Método / clúster*], [*N*], [*E*], [*O*], [*A*], [*C*], [*Imp.*], [*SS*], [*Perfil sociodemográfico (categoría del valor medio)*],
    midrule,
    [K-Means, clúster 0 ($n = 955$)], [-0.327], [0.066], [-0.395], [0.309], [*0.495*], [-0.554], [-0.602], [35--44 años, femenino, pregrado],
    [K-Means, clúster 1 ($n = 930$)], [0.336], [-0.069], [0.405], [-0.318], [-0.509], [*0.583*], [*0.612*], [25--34 años, masculino, técnico],
    midrule,
    [Jerárquico, clúster 0 ($n = 904$)], [0.205], [0.021], [0.448], [-0.175], [-0.304], [*0.406*], [*0.491*], [25--34 años, masculino, técnico],
    [Jerárquico, clúster 1 ($n = 981$)], [-0.189], [-0.019], [-0.413], [0.161], [*0.280*], [-0.361], [-0.459], [35--44 años, femenino, pregrado],
    midrule,
    [HDBSCAN, ruido $-1$ ($n = 1633$)], [-0.004], [-0.025], [0.016], [-0.006], [-0.012], [0.025], [0.006], [25--34 años, masculino, técnico],
    [HDBSCAN, clúster 0 ($n = 176$)], [-0.063], [0.145], [-0.378], [0.163], [*0.320*], [-0.396], [-0.445], [35--44 años, femenino, pregrado],
    [HDBSCAN, clúster 1 ($n = 76$)], [0.233], [0.198], [0.515], [-0.260], [-0.502], [*0.558*], [*0.827*], [18--24 años, masculino, univ. sin título],
    bottomrule,
  ),
  caption: [Promedio de los rasgos psicométricos estandarizados por grupo. N: neuroticismo, E: extraversión, O: apertura, A: amabilidad, C: responsabilidad, Imp.: impulsividad, SS: búsqueda de sensaciones],
) <tab:perfil>

== Consumo de sustancias por grupo

Al cruzar la partición con el consumo binarizado (@tab:consumo), el clúster 1 presenta prevalencias mucho mayores en casi todas las sustancias recreativas e ilícitas: cannabis (93.98 % frente a 62.62 %), éxtasis (65.48 % frente a 26.70 %), _legal highs_ (65.70 % frente a 18.85 %), LSD (62.26 % frente a 24.82 %) y hongos (67.53 % frente a 28.80 %). En cambio, alcohol, cafeína y chocolate son consumidos por más del 97 % de ambos grupos.

Para comprobar que estas diferencias no se deben al azar se aplicó una prueba Chi-cuadrado de independencia entre el clúster y el consumo de cada sustancia (@tab:chi2). Las mayores asociaciones corresponden a _legal highs_ ($chi^2 = 422.73$), éxtasis (283.89), hongos (281.67), cannabis (269.01) y LSD (267.53), todas con $p < 0.001$. Alcohol, chocolate y Semer, una sustancia ficticia incluida en la encuesta como control, no muestran asociación significativa ($p > 0.05$).

#figure(
  placement: top,
  scope: "parent",
  table(
    columns: 8,
    align: (left, center, center, center, center, center, center, center),
    toprule,
    table.cell(rowspan: 2, align: horizon)[*Sustancia*],
    table.cell(colspan: 2)[*K-Means*], table.cell(colspan: 2)[*Jerárquico*], table.cell(colspan: 3)[*HDBSCAN*],
    table.hline(start: 1, end: 3, stroke: 0.4pt), table.hline(start: 3, end: 5, stroke: 0.4pt), table.hline(start: 5, end: 8, stroke: 0.4pt),
    [C0], [C1], [C0], [C1], [Ruido], [C0], [C1],
    midrule,
    [Cannabis], [62.62], [*93.98*], [*93.25*], [64.12], [79.30], [57.95], [*98.68*],
    [Éxtasis], [26.70], [*65.48*], [*64.49*], [28.64], [46.36], [24.43], [*84.21*],
    [_Legal highs_], [18.85], [*65.70*], [*67.59*], [18.35], [42.80], [15.91], [*84.21*],
    [LSD], [24.82], [*62.26*], [*59.29*], [28.54], [43.97], [22.73], [*76.32*],
    [Hongos], [28.80], [*67.53*], [*65.71*], [31.50], [48.62], [25.57], [*84.21*],
    [Metadona], [10.89], [*37.85*], [*37.83*], [11.62], [24.49], [7.39], [*56.58*],
    [Cocaína], [29.63], [*60.65*], [*56.97*], [33.84], [46.60], [24.43], [*56.58*],
    [Nicotina], [67.23], [*87.63*], [*86.39*], [68.91], [77.65], [66.48], [*94.74*],
    midrule,
    [Alcohol], [97.80], [98.60], [98.23], [98.17], [98.29], [97.16], [98.68],
    [Cafeína], [97.91], [99.25], [99.34], [97.86], [98.41], [99.43], [100.00],
    [Chocolate], [98.01], [98.60], [98.23], [98.37], [98.35], [98.86], [96.05],
    bottomrule,
  ),
  caption: [Prevalencia de consumo (%) de sustancias seleccionadas en cada grupo. En negrita, el grupo de mayor consumo de cada método cuando la diferencia es significativa],
) <tab:consumo>

// =====================================================================
= Agrupamiento jerárquico aglomerativo
// =====================================================================

== Selección del tipo de enlace

Se compararon los cuatro criterios de enlace con $K = 2$ sobre las mismas doce variables, con distancia euclidiana (@tab:enlaces). Los enlaces _average_ y _single_ obtienen la silueta más alta, pero solo porque separan uno o dos puntos atípicos y dejan al resto de la población en un único grupo, una partición sin valor para el análisis. El enlace _complete_ produce grupos desbalanceados y la silueta más baja. Ward es el único que genera dos grupos de tamaño similar con una silueta razonable. Además, minimiza el aumento de la varianza intra-grupo (@eq:ward), el mismo criterio que optimiza K-Means (@eq:kmeans), lo que hace comparables ambos métodos. Por eso se selecciona el enlace de Ward.

#figure(
  table(
    columns: 4,
    align: (left, center, center, center),
    toprule,
    [*Enlace*], [*Tamaños*], [*Menor (%)*], [*Silueta*],
    midrule,
    [*Ward*], [*904 / 981*], [*47.96*], [*0.1253*],
    [Complete], [1156 / 729], [38.67], [0.0734],
    [Average], [1883 / 2], [0.11], [0.2775],
    [Single], [1884 / 1], [0.05], [0.2894],
    bottomrule,
  ),
  caption: [Comparación de criterios de enlace con $K = 2$. "Menor" es el porcentaje de datos en el grupo más pequeño],
) <tab:enlaces>

== Dendrograma y número de grupos

El dendrograma con enlace de Ward (@fig:dendro) muestra que las cuatro últimas fusiones ocurren a distancias de 33.8, 35.7, 53.4 y 67.1. El mayor salto vertical está entre 53.4 y 67.1, así que un corte en ese intervalo, a una altura de 60, produce $K = 2$ grupos, de 904 y 981 personas. Un corte más bajo no se justifica: a una altura de 35, por ejemplo, ya se obtendrían cuatro grupos separados por distancias mucho menores, lo que indica que no hay subgrupos claramente diferenciados. Elegir $K = 2$ también es coherente con K-Means y permite comparar ambas particiones.

#figure(
  image("figuras/dendrograma.png", width: 100%),
  caption: [Dendrograma con enlace de Ward. La línea discontinua marca el corte a una altura de 60, que produce $K = 2$; las ramas están coloreadas según ese corte.],
) <fig:dendro>

== Partición obtenida

En la proyección PCA (@fig:jerarquico) la frontera ya no es un corte recto como en K-Means, sino una división diagonal con un solapamiento notable en el centro de la nube. Esto se debe a que el método no asigna cada punto al centroide más cercano, sino que construye los grupos mediante fusiones sucesivas de vecinos. Aun así, ambas particiones coinciden en el 81.4 % de las personas. La silueta de la partición jerárquica (0.1253) es menor que la de K-Means con el mismo $K$ (@tab:silueta), lo cual es esperable porque K-Means optimiza directamente la cohesión respecto al centroide.

#figure(
  image("figuras/jerarquico_pca.png", width: 82%),
  caption: [Partición jerárquica con $K = 2$ sobre la proyección PCA.],
) <fig:jerarquico>

== Caracterización y consumo

Los perfiles reproducen los de K-Means con las etiquetas invertidas (@tab:perfil). El clúster 0 es el grupo impulsivo (0.41) con alta búsqueda de sensaciones (0.49): el 61.17 % tiene entre 18 y 24 años, el 62.94 % son hombres, el 53.54 % reside en Estados Unidos y el 46.57 % tiene estudios universitarios sin título. El clúster 1 tiene mayor responsabilidad (0.28) y menor neuroticismo; el 61.88 % son mujeres, el 81.45 % reside en el Reino Unido y predominan el pregrado y la maestría.

El grupo joven (clúster 0) vuelve a mostrar el mayor consumo (@tab:consumo), por ejemplo, 93.25 % en cannabis y 64.49 % en éxtasis, frente a 64.12 % y 28.64 % del clúster 1. Las pruebas Chi-cuadrado (@tab:chi2) siguen la misma tendencia: _legal highs_ ($chi^2 = 466.35$), éxtasis (242.07) y cannabis (231.70) presentan las asociaciones más fuertes, mientras que alcohol, chocolate, nitrito de amilo y Semer no son significativos.

#figure(
  table(
    columns: 4,
    align: (left, right, right, right),
    toprule,
    [*Sustancia*], [*K-Means*], [*Jerárquico*], [*HDBSCAN*],
    midrule,
    [_Legal highs_], [422.73], [466.35], [105.23],
    [Éxtasis], [283.89], [242.07], [77.74],
    [Hongos], [281.67], [219.25], [75.66],
    [Cannabis], [269.01], [231.70], [61.95],
    [LSD], [267.53], [179.95], [64.39],
    [Anfetaminas], [199.06], [113.70], [46.06],
    [Metadona], [185.27], [174.82], [70.66],
    [Cocaína], [181.88], [100.76], [35.90],
    [Benzodiacepinas], [176.38], [96.03], [34.94],
    [Inhalantes (VSA)], [133.78], [75.88], [29.99],
    [Ketamina], [114.72], [101.80], [13.24],
    [Heroína], [111.07], [62.98], [26.70],
    [Nicotina], [110.67], [80.96], [25.03],
    [Crack], [86.06], [39.36], [13.31],
    [Nitrito de amilo], [11.75], ns[0.59], [8.39],
    [Cafeína], [5.09], [6.26], ns[2.33],
    [Semer (control)], ns[3.27], ns[3.57], ns[2.18],
    [Alcohol], ns[1.29], ns[0.00], ns[1.24],
    [Chocolate], ns[0.67], ns[0.00], ns[2.66],
    bottomrule,
  ),
  caption: [Estadístico $chi^2$ entre el grupo asignado y el consumo de cada sustancia. #super[†] No significativo ($p > 0.05$)],
) <tab:chi2>

// =====================================================================
= Agrupamiento por densidad con HDBSCAN
// =====================================================================

== Selección de hiperparámetros

Primero se evaluó la sensibilidad del modelo a `min_cluster_size`, con `min_samples = 10` (@tab:sensibilidad). Entre 40 y 80 puntos el algoritmo encuentra siempre dos grupos y deja el 85.52 % de los datos como ruido; desde 100 puntos no encuentra ningún grupo y todo el conjunto queda como ruido.

#figure(
  table(
    columns: 3,
    align: (center, center, center),
    toprule,
    [*`min_cluster_size`*], [*Clústeres*], [*Ruido (%)*],
    midrule,
    [40], [2], [85.52],
    [60], [2], [85.52],
    [80], [2], [85.52],
    [100], [0], [100.00],
    [150], [0], [100.00],
    [200], [0], [100.00],
    bottomrule,
  ),
  caption: [Sensibilidad de HDBSCAN a `min_cluster_size` (`min_samples = 10`)],
) <tab:sensibilidad>

Para analizar la densidad del conjunto se calculó la _core distance_ de cada punto con $k = 15$ vecinos y se usó su inverso, $1 \/ "core"_k (x)$, como estimación de densidad. Al ordenar los puntos de mayor a menor densidad (@fig:densidad) se obtiene una curva que decrece de forma suave y continua, sin saltos ni mesetas. Si existieran grupos de distinta densidad separados por regiones vacías, la curva mostraría cambios bruscos; su ausencia indica una única nube homogénea.

#figure(
  image("figuras/densidad_core.png", width: 95%),
  caption: [Densidad estimada como $1 \/ "core"_k (x)$ con $k = 15$, con los puntos ordenados de mayor a menor densidad.],
) <fig:densidad>

== Modelo final, MST y DBCV

El modelo final se entrenó con `min_cluster_size = min_samples = 15`. La @fig:mst muestra el Árbol de Expansión Mínima construido con la distancia de @eq:mreach: las aristas forman una sola estructura conectada, sin ramas aisladas por aristas mucho más largas que el resto.

#figure(
  image("figuras/mst_hdbscan.png", width: 95%),
  caption: [Árbol de Expansión Mínima de HDBSCAN. El color de cada arista refleja su distancia de alcanzabilidad mutua.],
) <fig:mst>

El modelo encuentra dos grupos pequeños, de 176 y 76 personas, y clasifica 1633 individuos (86.6 %) como ruido. El índice DBCV es 0.0001, prácticamente cero: los dos grupos no son más densos que su entorno ni están separados del resto de los datos. En la @fig:hdbscan ambos aparecen como pequeños núcleos en lados opuestos de la nube, rodeados por puntos de ruido.

#figure(
  image("figuras/hdbscan_pca.png", width: 82%),
  caption: [Resultado de HDBSCAN sobre la proyección PCA. El ruido corresponde a la etiqueta $-1$.],
) <fig:hdbscan>

== Caracterización y consumo

Aunque los grupos son pequeños, sus perfiles son extremos y coinciden con los de los métodos anteriores (@tab:perfil, @fig:box_hdbscan). El ruido tiene medias cercanas a cero en todos los rasgos, es decir, corresponde a la población promedio. El clúster 1 ($n = 76$) tiene la mayor búsqueda de sensaciones (0.83) e impulsividad (0.56); el 92.11 % tiene entre 18 y 24 años, el 92.11 % son hombres, el 78.95 % reside en Estados Unidos y el 78.95 % tiene estudios universitarios sin título. El clúster 0 ($n = 176$) tiene alta responsabilidad (0.32) y baja búsqueda de sensaciones (-0.45); el 96.02 % reside en el Reino Unido, el 77.27 % son mujeres y el 50.57 % tiene pregrado.

#figure(
  placement: top,
  scope: "parent",
  image("figuras/boxplot_hdbscan.png", width: 82%),
  caption: [Distribución de los rasgos psicométricos en los grupos de HDBSCAN, incluido el ruido ($-1$).],
) <fig:box_hdbscan>

El clúster 1 presenta las prevalencias más altas de todo el estudio (@tab:consumo): 98.68 % en cannabis y 84.21 % en éxtasis, _legal highs_ y hongos. El clúster 0 tiene las más bajas, y el ruido se ubica en valores intermedios. Las pruebas Chi-cuadrado (@tab:chi2) son significativas para la mayoría de sustancias ilícitas, aunque con estadísticos menores que en los métodos anteriores, porque el 86.6 % de los datos está en el ruido. Chocolate, cafeína, Semer y alcohol resultan independientes de los grupos.

// =====================================================================
= Comparación y conclusiones del Punto 1
// =====================================================================

La @tab:comparacion resume los tres modelos. K-Means y el método jerárquico producen particiones parecidas, de dos grupos de tamaño similar, con siluetas bajas (0.17 y 0.13) que reflejan el solapamiento entre grupos. HDBSCAN no fuerza a todos los puntos a pertenecer a un grupo: el resultado es que casi todo el conjunto queda como ruido y el DBCV es prácticamente nulo.

#figure(
  table(
    columns: 4,
    align: (left, center, center, center),
    toprule,
    [], [*K-Means*], [*Jerárquico*], [*HDBSCAN*],
    midrule,
    [Tipo], [Particional], [Jerárquico], [Densidad],
    [Grupos], [2], [2], [2 + ruido],
    [Tamaños], [955 / 930], [904 / 981], [176 / 76],
    [Ruido], [--], [--], [1633 (86.6 %)],
    [Validación], [Silueta 0.166], [Silueta 0.125], [DBCV 0.0001],
    bottomrule,
  ),
  caption: [Resumen comparativo de los tres métodos],
) <tab:comparacion>

Los tres métodos coinciden en la misma dimensión de variación: de un extremo joven, masculino, impulsivo, con alta búsqueda de sensaciones y alto consumo, a otro de mayor edad, femenino, responsable y con bajo consumo. La diferencia es cómo representan esa dimensión. K-Means y el método jerárquico la cortan en dos mitades, mientras que HDBSCAN solo conserva sus extremos más concentrados y deja el resto como ruido.

En conclusión, el conjunto no presenta grupos naturales bien separados, pero el agrupamiento sí permite identificar dos perfiles de personalidad y sociodemográficos con patrones de consumo significativamente distintos. El perfil joven, masculino, impulsivo y con alta búsqueda de sensaciones concentra un consumo mucho mayor de sustancias recreativas e ilícitas, mientras que el consumo de alcohol, cafeína y chocolate es generalizado y no distingue a los grupos.

// =====================================================================
= Conclusiones generales
// =====================================================================

== ¿Qué funcionó?

- K-Means con $K = 2$, elegido con el método del codo y el coeficiente de silueta, y el método jerárquico con enlace de Ward identifican dos perfiles coherentes entre sí, que coinciden en el 81.4 % de las asignaciones.

- Caracterizar los grupos con diagramas de caja, perfiles promedio y tablas cruzadas sociodemográficas permitió darles una interpretación clara, y las pruebas Chi-cuadrado confirmaron que la asociación entre los grupos y el consumo de la mayoría de sustancias es significativa.

- La sustancia ficticia Semer funcionó como control: no se asocia con ningún agrupamiento, lo que respalda que las diferencias encontradas en las demás sustancias no son un artefacto del método.

== ¿Qué no funcionó?

- Ningún método encontró grupos bien separados. Las siluetas son bajas (0.17 y 0.13), por lo que las particiones de K-Means y del método jerárquico dividen una nube continua más que descubrir grupos naturales.

- HDBSCAN dejó el 86.6 % de los datos como ruido y obtuvo un DBCV prácticamente nulo. Al aumentar `min_cluster_size` por encima de 80 no encontró ningún grupo.

- El coeficiente de silueta, por sí solo, no basta para elegir el enlace jerárquico: los enlaces _average_ y _single_ obtienen la silueta más alta, pero producen particiones degeneradas que aíslan uno o dos puntos.

== ¿Qué aprendimos?

- Las métricas de calidad deben interpretarse junto con el tamaño y el significado de los grupos, no de forma aislada.

- Cada método refleja sus supuestos. K-Means asigna cada punto a un grupo aunque los datos sean continuos; el dendrograma muestra a qué nivel se separan los grupos y ayuda a justificar el corte; y HDBSCAN reconoce que la mayoría de los puntos no pertenece a ninguna región densa.

- La elección de las variables de agrupamiento condiciona el resultado. Con otras variables o con otra ponderación de ellas, la estructura encontrada podría ser distinta.

// =====================================================================
// Referencias
// =====================================================================
#[
  #set text(size: 8pt)
  #heading(numbering: none)[Referencias]
  #bibliography("referencias.yml", title: none, style: "ieee")
]
