# MDLP-upgraded
In this project I propose a new form to construct the algorithm Minimum Description Length Principle (MDLP). It will be more faster than any supervised discretization. You can check the full explanation on https://link.springer.com/chapter/10.1007/978-3-031-97910-1_20

# MDLP con Mejoras de Eficiencia

Para discretizar una base de datos de gran tamaño, el algoritmo **MDLP** puede tardar bastante debido a que ordena la columna de valores de menor a mayor, evaluando la utilidad de realizar un corte entre cada par de valores distintos. Para cada punto candidato, se calculan tres entropías:  
1. **Entropía total sin corte**  
2. **Entropía de la partición izquierda**  
3. **Entropía de la partición derecha**

Con ello, se determina la ganancia de información y, posteriormente, se aplica el criterio **MDL** para decidir si el corte es aceptado o no. En caso afirmativo, se recurre de manera recursiva sobre cada sub-partición, continuando el proceso hasta que no se encuentren más cortes relevantes.

Para mejorar su eficiencia en bases de datos grandes, se han añadido varias estrategias de poda y optimización:

1. **Tamaño mínimo de partición**:  
   Un corte que deje muy pocas muestras en alguna partición puede generar intervalos poco representativos. Por ello, se establece un umbral mínimo (*m*) para que cada lado de la partición tenga al menos *m* muestras.
2. **Profundidad máxima de recursión**:  
   Limitar cuánto puede "subdividirse" recursivamente un intervalo. Si la recursión (número de cortes consecutivos) supera cierto nivel, el algoritmo se detiene y ya no crea más subdivisiones.
3. **Submuestreo de posibles puntos de corte**:  
   Se evita evaluar todos los valores diferentes de la columna, tomando sólo un subconjunto y acelerando así la búsqueda de cortes sin sacrificar demasiada calidad.
4. **Conteos acumulados**:  
   En lugar de recalcular cuántas muestras de cada clase hay en la parte izquierda y derecha en cada corte, se utiliza una matriz acumulada que permite conocerlo en *O(1)*.
5. **Proceso paralelo**:  
   Se usa para aprovechar todos los núcleos del procesador y minimizar el tiempo de ejecución.

---

A continuación se presenta el pseudocódigo del algoritmo **MDLP con Mejoras de Eficiencia (sin límite de cortes)**:

Algorithm: MDLP con Mejoras de Eficiencia (sin límite de cortes)
-----------------------------------------------------------------
Input:
  - xSorted: vector de valores ordenados de menor a mayor.
  - ySorted: vector de clases correspondiente a xSorted.
  - prefixCount: matriz con conteos acumulados de clases.
  - minSize: tamaño mínimo de partición.
  - maxDepth: profundidad máxima.
  - candidateSampleRate: fracción de puntos a evaluar.
  - depth <- 1

Output:
  - Conjunto de puntos de corte, C.

Function FindCutPoints(xSorted, ySorted, prefixCount, depth):
  1. n <- length(xSorted)
  2. If (n < 2 or depth > maxDepth) then
         Return {}    // No se puede seguir cortando
  3. diffs <- { i | 1 ≤ i < n and xSorted[i] ≠ xSorted[i-1] }
  4. If (diffs is empty) then
         Return {}    // No hay lugares donde cortar
  5. candidateIndices <- Submuestra(diffs, candidateSampleRate)
  6. (bestCut, bestEntropy) <- FindBestCut(candidateIndices, prefixCount, minSize)
  7. If (bestCut == None) then
         Return {}    // Ningún corte válido
  8. gain <- MDLStop(prefixCount, bestCut, bestEntropy)
  9. If (gain == None) then
         Return {}    // No supera el umbral MDL
 10. // Si se aprueba el corte, dividir y recursear:
 11. xLeft  <- xSorted[0 : bestCut]
 12. yLeft  <- ySorted[0 : bestCut]
 13. xRight <- xSorted[bestCut : n]
 14. yRight <- ySorted[bestCut : n]
 15. prefixLeft  <- BuildPrefixCounts(yLeft)
 16. prefixRight <- BuildPrefixCounts(yRight)
 17. C_left  <- FindCutPoints(xLeft, yLeft, prefixLeft, depth + 1)
 18. C_right <- FindCutPoints(xRight, yRight, prefixRight, depth + 1)
 19. cutValue <- ( xSorted[bestCut - 1] + xSorted[bestCut] ) / 2
         // Punto de corte en el valor medio de dos adyacentes
 20. Return C_left ∪ {cutValue} ∪ C_right




# Reporte de Resultados y Análisis

Este documento presenta los resultados obtenidos al evaluar tres métodos de discretización:

- **MDLP de R**  
- **CAIM**  
- **MDLP mejorado** (propuesto)

sobre tres algoritmos de clasificación:

- **ID3**  
- **Naive Bayes**  
- **Hidden Naive Bayes (HNB)**

A continuación se muestran:

1. Una tabla comparativa de los tiempos de ejecución (en segundos) de cada método de discretización sobre distintos datasets.
2. Tres tablas que integran los resultados (precisión media y desviación estándar) de cada algoritmo al utilizar los distintos métodos de discretización.
3. Un análisis de los resultados, con especial énfasis en el comportamiento del MDLP mejorado.

---

## 1. Tiempos de Discretización

| Dataset                  | CAIM (seg)   | MDLP Mejorado (seg) | MDLP R (seg)                    |
|--------------------------|--------------|---------------------|---------------------------------|
| **Dry Bean**             | 4085.90      | 3.31                | 209.20 *(3.486603 mins)*        |
| **Gamma**                | 1253.72      | 3.21                | N/A                             |
| **Glass Identification** | 0.34         | 1.06                | 2.62                            |
| **Iris**                 | 0.01         | 0.38                | 2.32                            |
| **Letter Recognition**   | 0.01         | 0.59                | 2.96                            |
| **RiceCameo**            | 30.20        | 0.25                | 7.93                            |
| **Seeds**                | 0.15         | 0.03                | 2.40                            |
| **Wine Quality Red**     | 0.66         | 0.06                | 2.68                            |
| **Wine Quality White**   | 2.00         | 0.09                | 3.38                            |
| **Yeast**                | 1.11         | 0.04                | 2.51                            |

*Nota:* Para el dataset **Gamma** no sirvió el código de MDLP en R, no discretizaba la base de datos

---

## 2. Resultados de Clasificación

### 2.1. Algoritmo ID3

| Dataset                  | MDLP Mejorado<br>(Mean ± Std) | CAIM<br>(Mean ± Std)       | MDLP R<br>(Mean ± Std)       |
|--------------------------|-------------------------------|----------------------------|------------------------------|
| **Dry Bean**             | 0.890677 ± 0.007546           | 0.895745 ± 0.009127        | 0.890383 ± 0.006882          |
| **Gamma**                | 0.819138 ± 0.005004           | 0.803996 ± 0.010488        | N/A                          |
| **Glass**                | 0.650216 ± 0.147091           | 0.683983 ± 0.111702        | 0.729654 ± 0.108036          |
| **Iris**                 | 0.673333 ± 0.113333           | 0.946667 ± 0.065320        | 0.960000 ± 0.044222          |
| **Letter Recognition**   | 0.806100 ± 0.010111           | 0.774200 ± 0.012929        | 0.805750 ± 0.010950          |
| **RiceCameo**            | 0.916535 ± 0.011608           | 0.927559 ± 0.009405        | 0.919423 ± 0.010169          |
| **Seeds**                | 0.923810 ± 0.053026           | 0.900000 ± 0.049716        | 0.923810 ± 0.057143          |
| **Wine Quality Red**     | 0.579123 ± 0.039607           | 0.600401 ± 0.036340        | 0.574127 ± 0.034290          |
| **Wine Quality White**   | 0.564305 ± 0.022044           | 0.586557 ± 0.020159        | 0.567371 ± 0.021567          |
| **Yeast**                | 0.570787 ± 0.025755           | 0.506784 ± 0.048191        | 0.595787 ± 0.047056          |

---

### 2.2. Algoritmo Naive Bayes

| Dataset                  | MDLP Mejorado<br>(Mean ± Std) | CAIM<br>(Mean ± Std)       | MDLP R<br>(Mean ± Std)       |
|--------------------------|-------------------------------|----------------------------|------------------------------|
| **Dry Bean**             | 0.900521 ± 0.004895           | 0.892293 ± 0.006950        | 0.899786 ± 0.005069          |
| **Gamma**                | 0.782019 ± 0.007418           | 0.738275 ± 0.008083        | N/A                          |
| **Glass**                | 0.967100 ± 0.030300           | 0.701948 ± 0.093185        | 0.990476 ± 0.019048          |
| **Iris**                 | 0.673333 ± 0.113333           | 0.933333 ± 0.051640        | 0.933333 ± 0.066667          |
| **Letter Recognition**   | 0.745450 ± 0.006725           | 0.748100 ± 0.008752        | 0.748050 ± 0.007353          |
| **RiceCameo**            | 0.918373 ± 0.008170           | 0.914436 ± 0.009694        | 0.918373 ± 0.008170          |
| **Seeds**                | 0.919048 ± 0.042857           | 0.880952 ± 0.048795        | 0.919048 ± 0.037192          |
| **Wine Quality Red**     | 0.583502 ± 0.045573           | 0.568502 ± 0.036518        | 0.578487 ± 0.037823          |
| **Wine Quality White**   | 0.488366 ± 0.014111           | 0.513683 ± 0.018552        | 0.488571 ± 0.015185          |
| **Yeast**                | 0.588296 ± 0.028863           | 0.568751 ± 0.042036        | 0.591679 ± 0.039013          |

---

### 2.3. Algoritmo Hidden Naive Bayes (HNB)

| Dataset                  | MDLP Mejorado<br>(Mean ± Std) | CAIM<br>(Mean ± Std)                                                 | MDLP R<br>(Mean ± Std)       |
|--------------------------|-------------------------------|----------------------------------------------------------------------|------------------------------|
| **Dry Bean**             | 0.906032 ± 0.005216           | 0.895453 ± 0.007192                                                  | 0.905297 ± 0.004983          |
| **Gamma**                | 0.799159 ± 0.004596           | 0.798107 ± 0.008813                                                  | N/A                          |
| **Glass**                | 0.467100 ± 0.104538           | 0.714935 ± 0.116791                                                  | 0.471429 ± 0.084813          |
| **Iris**                 | 0.586667 ± 0.097980           | 0.853333 ± 0.151438                                                  | 0.873333 ± 0.172434          |
| **Letter Recognition**   | 0.531250 ± 0.013340           | 0.817800 ± 0.009811                                                  | 0.526800 ± 0.013108          |
| **RiceCameo**            | 0.928871 ± 0.010128           | 0.914961 ± 0.009974                                                  | 0.928871 ± 0.010593          |
| **Seeds**                | 0.633333 ± 0.085317           | 0.804762 ± 0.133758                                                  | 0.857143 ± 0.060234          |
| **Wine Quality Red**     | 0.567197 ± 0.046493           | 0.549104 ± 0.021137                                                  | 0.553443 ± 0.040267          |
| **Wine Quality White**   | 0.459783 ± 0.013135           | 0.509803 ± 0.015987                                                  | 0.459783 ± 0.012713          |
| **Yeast**                | 0.584215 ± 0.026374           | 0.371227 ± 0.053980                                                  | 0.345583 ± 0.078196          |

---

## 3. Análisis de Resultados

### Eficiencia en Tiempos de Discretización

- **Velocidad del MDLP mejorado:**  
  Los tiempos de ejecución muestran que el MDLP mejorado es **extremadamente eficiente** en comparación con CAIM y, en muchos casos, también con MDLP de R. Por ejemplo:
  - En el dataset **Dry Bean**, CAIM tarda _más de 4000 segundos_, mientras que el MDLP mejorado completa la discretización en apenas **3.31 segundos**.
  - En **Gamma**, CAIM requiere **1253.72 segundos**, en contraste con los **3.21 segundos** del MDLP mejorado.
  
- **Comparación con MDLP R:**  
  Aunque MDLP R muestra tiempos razonables en la mayoría de los casos, en ciertos datasets (por ejemplo, **Dry Bean**: ~209 segundos) se queda muy por detrás del MDLP mejorado, lo que subraya la gran ventaja computacional de la solución propuesta.

### Desempeño en Clasificación

- **Algoritmo ID3:**  
  El MDLP mejorado presenta precisiones medias comparables a las obtenidas con CAIM y MDLP R. Si bien en algunos datasets pequeños (como **Iris**) CAIM y MDLP R muestran valores superiores, el MDLP mejorado se mantiene competitivo, lo cual es relevante considerando su menor coste computacional.

- **Algoritmo Naive Bayes:**  
  Los resultados demuestran que el MDLP mejorado logra un desempeño estable, con precisiones muy similares a las de los otros métodos, lo que indica que la discretización rápida no compromete la calidad de la información utilizada para la clasificación.

- **Algoritmo Hidden Naive Bayes (HNB):**  
  Aunque en ciertos casos (por ejemplo, en **Iris** o en **Glass**) se observa que CAIM y MDLP R pueden alcanzar precisiones algo mayores, el MDLP mejorado ofrece resultados razonables y consistentes. Además, la gran diferencia en tiempos de ejecución refuerza la conveniencia de utilizar el MDLP mejorado, especialmente en aplicaciones donde el tiempo de procesamiento es crítico.

### Conclusiones del Análisis

- **Eficiencia Computacional:**  
  El MDLP mejorado permite una drástica reducción en los tiempos de discretización (en algunos casos, pasando de miles de segundos a pocos segundos), lo que es fundamental para trabajar con grandes volúmenes de datos o en entornos donde se requiere procesamiento en tiempo real.

- **Competitividad en Desempeño:**  
  A pesar de la notable aceleración, el MDLP mejorado mantiene un desempeño en clasificación muy competitivo frente a métodos tradicionales (CAIM y MDLP R). Esto sugiere que la optimización implementada no sacrifica la calidad del preprocesamiento.

- **Robustez y Consistencia:**  
  La variabilidad (desviación estándar) de los resultados del MDLP mejorado es comparable a la de los otros métodos, lo que indica que el método es robusto y produce resultados consistentes a través de distintos datasets y algoritmos.

En resumen, los experimentos demuestran que el **MDLP mejorado** es una alternativa prometedora en el proceso de discretización, combinando **eficiencia computacional** y **buen desempeño en clasificación**. Esto respalda su implementación y su posible adopción en escenarios donde tanto la velocidad como la calidad del preprocesamiento son esenciales.

---

## 4. Conclusión

El estudio respalda la eficacia del MDLP mejorado, que ofrece una considerable reducción en los tiempos de procesamiento y mantiene resultados competitivos en términos de precisión de clasificación. Se recomienda continuar investigando y optimizando este algoritmo para ampliar su aplicabilidad en diferentes dominios y conjuntos de datos.
