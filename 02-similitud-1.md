# Similitud y vecinos cercanos {#similitud}




En esta parte consideraremos la tarea de agrupar eficientemente elementos muy similares
en conjuntos datos masivos. 

Algunos ejemplos de esta tarea son:

- Encontrar documentos similares en una colección de documentos. Esto puede 
servir para detectar
plagio, deduplicar noticias o páginas web, hacer *matching* de datos
de dos fuentes (por ejemplo, nombres completos de personas),
etc. Ver por ejemplo [Google News]((https://dl.acm.org/citation.cfm?id=1242610)).
- Encontrar usuarios similares (Netflix), en el sentido de que tienen gustos similares, o películas similares, en el sentido de qe le gustan a las mismas personas.
- Encontrar imágenes similares en una colección grande, ver por ejemplo [Pinterest](https://medium.com/@Pinterest_Engineering/detecting-image-similarity-using-spark-lsh-and-tensorflow-618636afc939).
- Uber: rutas similares que indican (fraude o abusos)[https://eng.uber.com/lsh/].
- Deduplicar registros de usuarios de algún servicio (por ejemplo, beneficiarios
de programas sociales).

Estos problemas no son triviales por dos razones:

- Los elementos que queremos comparar muchas veces están naturalmente representados en espacios de dimensión alta, y es relativamente costoso comparar un par (documentos, imágenes, usuarios, rutas). Muchas veces es preferible construir una representación más compacta y hacer comparaciones con las versiones comprimidas.
- Si la colección de elementos es grande ($N$), entonces el número de pares 
posibles es del orden de $N^2$, y es muy costoso hacer todas las posibles comparaciones para encontrar los elementos similares (por ejemplo, comparar
$100$ mil documentos, con unas $10$ mil comparaciones por segundo, tardaría alrededor de $5$ días).

Si tenemos que calcular *todas* las similitudes, no hay mucho qué hacer. Pero
muchas veces nos interesa encontrar pares de similitud alta, o completar tareas
más específicas como contar duplicados, etc. En estos casos, veremos que es
posible construir soluciones probabilísticas aproximadas para resolver estos
problemas de forma escalable. 

Aunque veremos más adelante métricas de similitud comunes como
la dada por la distancia euclideana o distancia coseno, por ejemplo, en 
esta primera parte nos concentramos en discutir similitud entre
pares de textos. Los textos los podemos ver como colecciones de palabras, o
de manera más general, como colecciones de cadenas.


## Similitud de conjuntos

Muchos de estos problemas de similitud se pueden pensar como 
problemas de similitud entre conjuntos. Por ejemplo, los documentos son conjuntos de palabras, conjuntos
de pares de palabras, sucesiones de caracteres,
una película se puede ver como el conjunto de personas a las que les gustó, o una ruta
como un conjunto de tramos, etc.

Hay muchas medidas que son útiles para cuantificar la similitud entre conjuntos. Una que es popular, y que explotaremos por sus propiedades, es la similitud de Jaccard:


\BeginKnitrBlock{resumen}<div class="resumen">La **similitud de Jaccard** de los conjuntos $A$ y $B$ está dada por
$$sim(A,B) = \frac{|A\cap B|}{|A\cup B|}$$</div>\EndKnitrBlock{resumen}

Esta medida cuantifica qué tan cerca está la unión de $A$ y $B$ de su intersección. Cuanto más parecidos sean $A\cup B$ y $A\cap B$, más similares son los conjuntos. En términos geométricos, es el área de la intersección entre el área de la unión. 

#### Ejercicio {-}

Calcula la similitud de Jaccard entre los conjuntos $A=\{5,2,34,1,20,3,4\}$
 y $B=\{19,1,2,5\}$
 


```r
library(tidyverse)
options(digits = 3)
sim_jaccard <- \(a, b)  length(intersect(a, b)) / length(union(a, b))
sim_jaccard(c(0,1,2,5,8), c(1,2,5,8,9))
## [1] 0.667
sim_jaccard(c(2,3,5,8,10), c(1,8,9,10))
## [1] 0.286
sim_jaccard(c(3,2,5), c(8,9,1,10))
## [1] 0
```


## Representación de documentos como conjuntos

Hay varias maneras de representar documentos como conjuntos. Las más simples son:

1. Los documentos son colecciones de palabras, o conjuntos de sucesiones de palabras de tamaño $n$.
2. Los documentos son colecciones de caracteres, o conjuntos de sucesiones de caracteres (cadenas) de tamaño $k$.


La primera representación se llama *representación de n-gramas*, y la segunda *representación de k-tejas*, 
o $k$-_shingles_. Nótese que en ambos casos, representaciones de dos documentos con secciones parecidas acomodadas en distintos lugares tienden a ser similares.

Consideremos una colección de textos cortos:


```r
textos <- c("el perro persigue al gato pero no lo alcanza", 
            "el gato persigue al perro, pero no lo alcanza", 
            "este es el documento de ejemplo", 
            "este no es el documento de los ejemplos",
            "documento más corto",
            "otros animales pueden ser mascotas")
```

Abajo mostramos la representacion en bolsa de palabras (1-gramas) y la representación en bigramas (2-gramas) de los primeros dos documentos:


```r
# Bolsa de palabras (1-gramas)
tokenizers::tokenize_ngrams(textos[1:2], n = 1) |> map(unique)
```

```
## [[1]]
## [1] "el"       "perro"    "persigue" "al"       "gato"     "pero"     "no"      
## [8] "lo"       "alcanza" 
## 
## [[2]]
## [1] "el"       "gato"     "persigue" "al"       "perro"    "pero"     "no"      
## [8] "lo"       "alcanza"
```


```r
# bigramas
tokenizers::tokenize_ngrams(textos[1:2], n = 2) |> map(unique)
```

```
## [[1]]
## [1] "el perro"       "perro persigue" "persigue al"    "al gato"       
## [5] "gato pero"      "pero no"        "no lo"          "lo alcanza"    
## 
## [[2]]
## [1] "el gato"       "gato persigue" "persigue al"   "al perro"     
## [5] "perro pero"    "pero no"       "no lo"         "lo alcanza"
```

La representación en _k-tejas_ es otra posibilidad:


```r
calcular_tejas <- function(x, k = 2){
  tokenizers::tokenize_character_shingles(x, n = k, lowercase = FALSE,
    simplify = TRUE, strip_non_alpha = FALSE)
}
# 2-tejas
calcular_tejas(textos[1:2], k = 2) |> map(unique)
```

```
## [[1]]
##  [1] "el" "l " " p" "pe" "er" "rr" "ro" "o " "rs" "si" "ig" "gu" "ue" "e " " a"
## [16] "al" " g" "ga" "at" "to" " n" "no" " l" "lo" "lc" "ca" "an" "nz" "za"
## 
## [[2]]
##  [1] "el" "l " " g" "ga" "at" "to" "o " " p" "pe" "er" "rs" "si" "ig" "gu" "ue"
## [16] "e " " a" "al" "rr" "ro" "o," ", " " n" "no" " l" "lo" "lc" "ca" "an" "nz"
## [31] "za"
```

```r
# 4-tejas:"
calcular_tejas(textos[1:2], k = 4) |> map(unique)
```

```
## [[1]]
##  [1] "el p" "l pe" " per" "perr" "erro" "rro " "ro p" "o pe" "pers" "ersi"
## [11] "rsig" "sigu" "igue" "gue " "ue a" "e al" " al " "al g" "l ga" " gat"
## [21] "gato" "ato " "to p" "pero" "ero " "ro n" "o no" " no " "no l" "o lo"
## [31] " lo " "lo a" "o al" " alc" "alca" "lcan" "canz" "anza"
## 
## [[2]]
##  [1] "el g" "l ga" " gat" "gato" "ato " "to p" "o pe" " per" "pers" "ersi"
## [11] "rsig" "sigu" "igue" "gue " "ue a" "e al" " al " "al p" "l pe" "perr"
## [21] "erro" "rro," "ro, " "o, p" ", pe" "pero" "ero " "ro n" "o no" " no "
## [31] "no l" "o lo" " lo " "lo a" "o al" " alc" "alca" "lcan" "canz" "anza"
```


**Observaciones**:

1. Los _tokens_ son las unidades básicas de análisis. Los _tokens_ son palabras para los n-gramas (cuya definición no es del todo simple) y caracteres para las k-tejas. Podrían ser también oraciones, por ejemplo.
2. Nótese que en ambos casos es posible hacer algo de preprocesamiento para
obtener la representación. Transformaciones usuales son:

  - Eliminar puntuación y/o espacios. 
  - Convertir los textos a minúsculas.
  - Esto incluye decisiones acerca de qué hacer con palabras compuestas (por ejemplo, con un guión), palabras que denotan un concepto (Reino Unido, por ejemplo) y otros detalles.

3. Si lo que nos interesa principalmente
similitud textual (no significado, o polaridad, etc.) entre documentos, entonces podemos usar $k$-tejas, con un mínimo de preprocesamiento. Esta
representación es **simple y flexible** en el sentido de que se puede adaptar para documentos muy cortos (mensajes o tweets, por ejemplo), pero también para documentos más grandes.

Por estas razones, no concentramos por el momento en $k$-tejas


\BeginKnitrBlock{resumen}<div class="resumen">**Tejas (shingles)**
  
Sea $k>0$ un entero. Las $k$-tejas ($k$-shingles) de un documento d
 es el conjunto de todas las corridas (distintas) de $k$
caracteres sucesivos.
Escogemos $k$ suficientemente grande, de forma que la probabilidad de que
una teja particular ocurra en un texto dado sea relativamente baja.</div>\EndKnitrBlock{resumen}


#### Ejemplo {-}
Documentos textualmente similares tienen tejas similares:


```r
# calcular tejas
textos
## [1] "el perro persigue al gato pero no lo alcanza" 
## [2] "el gato persigue al perro, pero no lo alcanza"
## [3] "este es el documento de ejemplo"              
## [4] "este no es el documento de los ejemplos"      
## [5] "documento más corto"                          
## [6] "otros animales pueden ser mascotas"
tejas_doc <- calcular_tejas(textos, k = 4)
# calcular similitud de jaccard entre algunos pares
sim_jaccard(tejas_doc[[1]], tejas_doc[[2]])
## [1] 0.773
sim_jaccard(tejas_doc[[1]], tejas_doc[[3]])
## [1] 0
sim_jaccard(tejas_doc[[4]], tejas_doc[[5]])
## [1] 0.156
```

Podemos calcular todas las similitudes:


```r
tejas_tbl <- crossing(id_1 = 1:length(textos), id_2 = 1:length(textos)) |>
  filter(id_1 < id_2) |> 
  mutate(tejas_1 = tejas_doc[id_1], tejas_2 = tejas_doc[id_2]) |>   
  mutate(sim = map2_dbl(tejas_1, tejas_2, ~sim_jaccard(.x, .y))) |> 
  select(id_1, id_2, sim)
tejas_tbl
```

```
## # A tibble: 15 × 3
##     id_1  id_2    sim
##    <int> <int>  <dbl>
##  1     1     2 0.773 
##  2     1     3 0     
##  3     1     4 0.0137
##  4     1     5 0     
##  5     1     6 0     
##  6     2     3 0     
##  7     2     4 0.0133
##  8     2     5 0     
##  9     2     6 0     
## 10     3     4 0.6   
## 11     3     5 0.189 
## 12     3     6 0     
## 13     4     5 0.156 
## 14     4     6 0     
## 15     5     6 0
```


pero nótese que, como señalamos arriba, esta operación será muy
costosa incluso si la colección de textos es de tamaño moderado.


- Si los textos
son cortos, entonces basta tomar valores como $k=4,5$, pues hay un total de $27^4$ tejas
de tamaño $4$, y el número de tejas de un documento corto (mensajes, tweets) es mucho más bajo que
$27^4$ (nota: ¿puedes explicar por qué este argumento no es exactamente correcto?)

- Para documentos grandes, como noticias o artículos, es mejor escoger un tamaño más grande,
como $k=9,10$, pues en documentos largos puede haber cientos de miles
de caracteres. Si $k$ fuera más chica entonces una gran parte de las tejas aparecerá en muchos de los documentos, y todos los documentos tendrían similitud alta.

- Evitamos escoger $k$ demasiado grande, pues entonces los únicos documentos similares tendrían
que tener subcadenas largas exactamente iguales. Por ejemplo: "Batman y Robin" y "Robin y Batman" son algo
similares si usamos tejas de tamaño 3, pero son muy distintas si usamos tejas de tamaño 8:

#### Ejemplo {-}


```r
tejas_1 <- calcular_tejas("Batman y Robin", k = 3)
tejas_2 <- calcular_tejas("Robin y Batman", k = 3)
sim_jaccard(tejas_1, tejas_2)
```

```
## [1] 0.6
```

```r
tejas_1 <- calcular_tejas("Batman y Robin", k = 8)
tejas_2 <- calcular_tejas("Robin y Batman", k = 8)
sim_jaccard(tejas_1, tejas_2)
```

```
## [1] 0
```
## Representación matricial

Podemos usar una matriz binaria para guardar todas las
representaciones en k-tejas de nuestra colección de documentos. Puede usarse
una representación rala (_sparse_) si es necesario:


```r
dtejas_tbl <- tibble(id = paste0("doc_", 1:length(textos)), 
    tejas = tejas_doc) |> 
  unnest(cols = tejas) |> 
  unique() |> mutate(val = 1) |> 
  pivot_wider(names_from = id, values_from = val, values_fill = list(val = 0)) |> 
  arrange(tejas) # opcionalmente ordenamos tejas
dtejas_tbl
```

```
## # A tibble: 123 × 7
##    tejas  doc_1 doc_2 doc_3 doc_4 doc_5 doc_6
##    <chr>  <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>
##  1 " al "     1     1     0     0     0     0
##  2 " alc"     1     1     0     0     0     0
##  3 " ani"     0     0     0     0     0     1
##  4 " cor"     0     0     0     0     1     0
##  5 " de "     0     0     1     1     0     0
##  6 " doc"     0     0     1     1     0     0
##  7 " eje"     0     0     1     1     0     0
##  8 " el "     0     0     1     1     0     0
##  9 " es "     0     0     1     1     0     0
## 10 " gat"     1     1     0     0     0     0
## # … with 113 more rows
```


¿Cómo calculamos la similitud de Jaccard usando estos datos?

Calcular la unión e intersección se puede hacer haciendo OR y AND de las columnas, y
entonces podemos calcular la similitud

```r
inter_12 <- sum(dtejas_tbl$doc_1 & dtejas_tbl$doc_2)
union_12 <- sum(dtejas_tbl$doc_1 | dtejas_tbl$doc_2)
similitud <- inter_12/union_12
similitud # comparar con el número que obtuvimos arriba.
```

```
## [1] 0.773
```

El cálculo para todos los documentos podríamos hacerlo (aunque veremos que normalmente
no haremos esto si no necesitamos calcular todas las similitudes) con:


```r
mat_td <- dtejas_tbl |> select(-tejas) |> as.matrix() |> t()
1 - dist(mat_td, method = "binary")
```

```
##        doc_1  doc_2  doc_3  doc_4  doc_5
## doc_2 0.7727                            
## doc_3 0.0000 0.0000                     
## doc_4 0.0137 0.0133 0.6000              
## doc_5 0.0000 0.0000 0.1892 0.1556       
## doc_6 0.0000 0.0000 0.0000 0.0000 0.0000
```


## Minhash y reducción probabilística de dimensionalidad

Para una colección grande de documentos
la representación binaria de la colección de documentos 
puede tener un número muy grande de renglones. Puede ser posible
crear un número más chico de nuevos _features_ (ojo: aquí los renglones
son las "variables", y los casos son las columnas) con los que
sea posible obtener una buena aproximación de la similitud.

La idea básica es la siguiente:

- Supongamos que numeramos las tejas 1, 2, \ldots, N.
- Escogemos una función al azar (una función _hash_) que mapea cadenas cortas a un número grande de enteros, de manera existe muy baja probabilidad de colisiones, y no hay correlación entre las cadenas y el valor al que son mapeados.
- Si un documento tiene tejas $T$, aplicamos la función hash a cada teja de $T$, y calculamos el mínimo de estos valores hash. 
- Repetimos este proceso para varias funciones hash fijas, por ejemplo $k= 5$
- Los valores mínimos obtenidos nos dan una representación en dimensión baja de cada
documento.

#### Ejemplo {-}



```r
textos_tbl <- tibble(doc_id = 1:length(textos), texto = textos)
tejas_tbl <- tibble(doc_id = 1:length(textos), tejas = tejas_doc)
tejas_tbl
```

```
## # A tibble: 6 × 2
##   doc_id tejas     
##    <int> <list>    
## 1      1 <chr [41]>
## 2      2 <chr [42]>
## 3      3 <chr [28]>
## 4      4 <chr [36]>
## 5      5 <chr [16]>
## 6      6 <chr [31]>
```

Creamos una función hash:


```r
set.seed(813)
generar_hash <- function(){
  r <- as.integer(stats::runif(1, 1, 2147483647))
  funcion_hash <- function(tejas){
        digest::digest2int(tejas, seed = r) 
  }
  funcion_hash
}
h_1 <- generar_hash()
```

Y aplicamos la función a cada teja del documento 1, y tomamos el mínimo:


```r
hashes_1 <- h_1(tejas_tbl$tejas[[1]])
hashes_1
```

```
##  [1] -1318809190 -1534091290 -1401861150 -1601894665   781339434  -519860631
##  [7]  2116727945 -1824301917 -1401861150 -1371561364 -1385084918  -821046029
## [13]  1766711521  1952075680   569109680 -1412107908  1059544482 -1866546594
## [19]  2090868926  -455965089   784118133  1421354549 -1397404756  -481987742
## [25] -1824301917 -1401861150  1157451749   698137483  -623448608   544014704
## [31]  -587926856  1455454405   950121497  -165719415  2119479774  2115904977
## [37]  1519310299  1652203243  -667865842  1219377605 -1500087628
```


```r
minhash_1 <- min(hashes_1)
minhash_1
```

```
## [1] -1866546594
```

Consideramos este _minhash_ como un descriptor del documento. Generalmente
usamos más de un descriptor. En el siguiente ejemplo usamos tres funciones
hash creadas de manera independiente:



```r
hashes <- map(1:4, ~ generar_hash())

docs_firmas <- tejas_tbl |> 
  mutate(firma = map(tejas, \(lista) map_int(hashes, \(h) min(h(lista))))) |> 
  select(doc_id, firma) |> 
  unnest_wider(firma, names_sep = "_")
docs_firmas
```

```
## # A tibble: 6 × 5
##   doc_id     firma_1     firma_2     firma_3     firma_4
##    <int>       <int>       <int>       <int>       <int>
## 1      1 -2129712961 -2124594172 -2073157333 -1982715048
## 2      2 -2129712961 -2124594172 -2073157333 -1982715048
## 3      3 -2139075502 -2093452194 -1959662839 -2048484934
## 4      4 -2139075502 -2093452194 -1959662839 -2048484934
## 5      5 -2106131386 -2093452194 -2127642881 -1984764210
## 6      6 -2115397946 -2087727654 -2074217109 -1986993146
```

Nótese ahora que en documentos muy similares, varios de los minhashes coinciden. Esto
es porque la teja donde ocurrió el mínimo está en los dos documentos. Entonces
cuando los las tejas de dos documentos son muy similares, es muy probable que sus
minhashes coincidan.

¿Cuál es la probabilidad de que la firma coincida para un documento?

\BeginKnitrBlock{resumen}<div class="resumen">Sea $h$ una función _hash_ escogida escogida al azar, y $a$ y $b$ dos documentos dados
dadas. Entonces
$$P(minhash_h(a) = minhash_h(b)) = sim(a, b)$$
donde $sim$ es la similitud de Jaccard basada en las tejas usadas.
Sean $h_1, h_2, \ldots h_n$ funciones _hash_ escogidas al azar de
manera independiente. Si $n$ es grande, entonces por la ley de los grandes números
$$sim(a,b) \approx \frac{|h_j : minhash_{h_j}{\pi_j}(a) = minhash_{h_j}(b)|}{n},$$
es decir, la similitud de Jaccard es aproximadamente la proporción 
de elementos de las firmas que coinciden.</div>\EndKnitrBlock{resumen}

Ahora damos un argumento para demostrar este resultado:

Supongamos que el total de tejas de los dos documentos es $|A\cup B|$, y el 
número de tejas que tienen en común es $|A\cap B|$. Sea $h$ la función _hash_
que escogimos al azar. 

Para fijar ideas, puedes suponer que las tejas están numeradas $1,\ldots, M$, y 
la función _hash_ es una permutación aleatoria de estos números.


Entonces:

1. El mínimo de $h$ puede ocurrir en cualquier elemento de $|A\cup B|$ con
la misma probabilidad.
2. Los minhashes de $a$ y $b$ coinciden si y sólo si el mínimo de $h$ ocurre en un elemento
de $|A\cap B|$
3. Por 1 y 2, la probabilidad de que esto ocurra es
$$\frac{|A\cap B|}{|A\cup B|},$$
que es la similitud de Jaccard. 

Nótese que esto requiere que la familia de donde escogemos nuestra función
_hash_ cumple, al menos aproximadamente, las propiedades 1 y 2. Para que 1 ocurra,
la familia debe ser suficientemente grande y variada: por ejemplo, esto fallaría si
todas las cadenas que comienzan con "a" se mapean a números chicos. Para que
ocurra 2, no debe haber colisiones (cadenas distintas que se mapean al mismo valor). 

**Observaciónes**: 

- Una familia que cumple de manera exacta estas dos propiedades
es la familia de permutaciones que mencionamos arriba: numeramos las tejas, construimos
una permutación al azar, y luego aplicamos esta función de permutaciones a los índices
de las tejas. La razón por la que esta familia no es utiliza típicamente es porque
es costosa si el número de tejas es grande: primero hay que escoger un ordenamiento al azar, y luego es necesario almacenarlo.

- Muchas veces, se utiliza una función hash con aritmética 
modular como sigue: sea $M$ el número total
de tejas, y sea $p$ un número primo fijo grande (al menos $p > M$). 
Numeramos las tejas. Ahora escogemos dos enteros $a$ y $b$ al azar, y hacemos
$$h(x) = (ax + b\mod p) \mod M$$
Estas funciones se pueden seleccionar y aplicar rápidamente, y sólo tenemos que almacenar los coeficientes $a$ y $b$.

- En el enfoque que vimos arriba, utilizamos directamente una función _hash_ de cadenas
que está diseñada para cumplir 1 y 2 de manera aproximada.

\BeginKnitrBlock{resumen}<div class="resumen">**Resumen**. Con el método de minhash, representamos a los documentos con un 
número relativamente chico de atributos numéricos (reducción de dimensionalidad). Esta
respresentación tiene la propiedad de que textos muy similares con probabilidad
alta coinciden en uno o más de los descriptores.</div>\EndKnitrBlock{resumen}

## Agrupando textos de similitud alta

Nuestro siguiente paso es evitar hacer la comparación de todos los pares de descriptores.
Para esto hacemos un clustering no exhaustivo basado en los descriptores que
acabamos de construir.

Recordemos que tenemos


```r
docs_firmas
```

```
## # A tibble: 6 × 5
##   doc_id     firma_1     firma_2     firma_3     firma_4
##    <int>       <int>       <int>       <int>       <int>
## 1      1 -2129712961 -2124594172 -2073157333 -1982715048
## 2      2 -2129712961 -2124594172 -2073157333 -1982715048
## 3      3 -2139075502 -2093452194 -1959662839 -2048484934
## 4      4 -2139075502 -2093452194 -1959662839 -2048484934
## 5      5 -2106131386 -2093452194 -2127642881 -1984764210
## 6      6 -2115397946 -2087727654 -2074217109 -1986993146
```

Ahora agrupamos documentos que comparten alguna firma. A los grupos
que coinciden en cada firma les lammamos _cubetas_:


```r
cubetas_tbl <- docs_firmas |> pivot_longer(contains("firma_"), "n_firma") |> 
  mutate(cubeta = paste(n_firma, value)) |> 
  group_by(cubeta) |> 
  summarise(documentos = list(doc_id)) |> 
  mutate(num_docs = map_int(documentos, length))
cubetas_tbl
```

```
## # A tibble: 15 × 3
##    cubeta              documentos num_docs
##    <chr>               <list>        <int>
##  1 firma_1 -2106131386 <int [1]>         1
##  2 firma_1 -2115397946 <int [1]>         1
##  3 firma_1 -2129712961 <int [2]>         2
##  4 firma_1 -2139075502 <int [2]>         2
##  5 firma_2 -2087727654 <int [1]>         1
##  6 firma_2 -2093452194 <int [3]>         3
##  7 firma_2 -2124594172 <int [2]>         2
##  8 firma_3 -1959662839 <int [2]>         2
##  9 firma_3 -2073157333 <int [2]>         2
## 10 firma_3 -2074217109 <int [1]>         1
## 11 firma_3 -2127642881 <int [1]>         1
## 12 firma_4 -1982715048 <int [2]>         2
## 13 firma_4 -1984764210 <int [1]>         1
## 14 firma_4 -1986993146 <int [1]>         1
## 15 firma_4 -2048484934 <int [2]>         2
```
Ahora filtramos las cubetas que tienen más de un elemento:


```r
cubetas_tbl <- cubetas_tbl |> 
  filter(num_docs > 1)
cubetas_tbl 
```

```
## # A tibble: 8 × 3
##   cubeta              documentos num_docs
##   <chr>               <list>        <int>
## 1 firma_1 -2129712961 <int [2]>         2
## 2 firma_1 -2139075502 <int [2]>         2
## 3 firma_2 -2093452194 <int [3]>         3
## 4 firma_2 -2124594172 <int [2]>         2
## 5 firma_3 -1959662839 <int [2]>         2
## 6 firma_3 -2073157333 <int [2]>         2
## 7 firma_4 -1982715048 <int [2]>         2
## 8 firma_4 -2048484934 <int [2]>         2
```

Y de aquí extraemos **pares candidatos** que tienen alta probabilidad de
ser muy similares:


```r
pares_tbl <- cubetas_tbl |> 
  mutate(pares_cand = map(documentos, ~ combn(.x, 2, simplify = FALSE))) |> 
  select(cubeta, pares_cand) |> 
  unnest(pares_cand) |> 
  unnest_wider(pares_cand, names_sep = "_") 
pares_tbl
```

```
## # A tibble: 10 × 3
##    cubeta              pares_cand_1 pares_cand_2
##    <chr>                      <int>        <int>
##  1 firma_1 -2129712961            1            2
##  2 firma_1 -2139075502            3            4
##  3 firma_2 -2093452194            3            4
##  4 firma_2 -2093452194            3            5
##  5 firma_2 -2093452194            4            5
##  6 firma_2 -2124594172            1            2
##  7 firma_3 -1959662839            3            4
##  8 firma_3 -2073157333            1            2
##  9 firma_4 -1982715048            1            2
## 10 firma_4 -2048484934            3            4
```


```r
pares_tbl <- pares_tbl |> select(-cubeta) |> 
  unique()
pares_tbl
```

```
## # A tibble: 4 × 2
##   pares_cand_1 pares_cand_2
##          <int>        <int>
## 1            1            2
## 2            3            4
## 3            3            5
## 4            4            5
```

Nótese que con este proceso evitamos hacer todas las comparaciones, y el método
tiene complejidad lineal en el tamaño de la colección de documentos. Una vez que tenemos
los pares, podemos calcular la similitud exacta de solamente esos documentos:


```r
pares_tbl |> 
  left_join(tejas_tbl |> rename(pares_cand_1 = doc_id, texto_1 = tejas)) |> 
  left_join(tejas_tbl |> rename(pares_cand_2 = doc_id, texto_2 = tejas)) |> 
  mutate(score = map2_dbl(texto_1, texto_2, ~ sim_jaccard(.x, .y))) |> 
  select(-contains("texto"))
```

```
## Joining, by = "pares_cand_1"
```

```
## Joining, by = "pares_cand_2"
```

```
## # A tibble: 4 × 3
##   pares_cand_1 pares_cand_2 score
##          <int>        <int> <dbl>
## 1            1            2 0.773
## 2            3            4 0.6  
## 3            3            5 0.189
## 4            4            5 0.156
```

Si queremos capturar solamente aquellos pares de similitud muy alta,
podemos también combinar firmas para formar cubetas donde las dos firmas coinciden:


```r
cubetas_tbl <- docs_firmas |> 
  mutate(cubeta = paste(firma_1, firma_2)) |> 
  group_by(cubeta) |> 
  summarise(documentos = list(doc_id)) |> 
  mutate(num_docs = map_int(documentos, length))
cubetas_tbl
```

```
## # A tibble: 4 × 3
##   cubeta                  documentos num_docs
##   <chr>                   <list>        <int>
## 1 -2106131386 -2093452194 <int [1]>         1
## 2 -2115397946 -2087727654 <int [1]>         1
## 3 -2129712961 -2124594172 <int [2]>         2
## 4 -2139075502 -2093452194 <int [2]>         2
```


```r
pares_tbl <- cubetas_tbl |> 
  filter(num_docs > 1) |> 
  mutate(pares_cand = map(documentos, ~ combn(.x, 2, simplify = FALSE))) |> 
  select(cubeta, pares_cand) |> 
  unnest(pares_cand) |> 
  unnest_wider(pares_cand, names_sep = "_") |> 
  left_join(tejas_tbl |> rename(pares_cand_1 = doc_id, texto_1 = tejas)) |> 
  left_join(tejas_tbl |> rename(pares_cand_2 = doc_id, texto_2 = tejas)) |> 
  mutate(score = map2_dbl(texto_1, texto_2, ~ sim_jaccard(.x, .y))) |> 
  select(-contains("texto"))
```

```
## Joining, by = "pares_cand_1"
```

```
## Joining, by = "pares_cand_2"
```

```r
pares_tbl
```

```
## # A tibble: 2 × 4
##   cubeta                  pares_cand_1 pares_cand_2 score
##   <chr>                          <int>        <int> <dbl>
## 1 -2129712961 -2124594172            1            2 0.773
## 2 -2139075502 -2093452194            3            4 0.6
```

## Ejemplo: tweets 

Ahora buscaremos tweets similares en una colección de un [dataset de
kaggle](https://www.kaggle.com/rgupta09/world-cup-2018-tweets/home?utm_medium=email&utm_source=mailchimp&utm_campaign=datanotes-20180823).
