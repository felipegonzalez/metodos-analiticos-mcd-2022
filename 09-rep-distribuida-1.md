# Representación de palabras y word2vec

En esta parte empezamos a ver los enfoques más modernos (redes neuronales) para construir
modelos de lenguajes y resolver tareas de NLP. Se trata de modelos de lenguaje que incluyen más 
estructura, son más fáciles de regularizar y de ampliar si es necesario para incluir
dependencias de mayor distancia. El método de conteo/suavizamiento de ngramas es simple y funciona 
bien para algunas tareas, pero podemos construir mejores modelos con enfoques más estructurados, y con
más capacidad para aprender aspectos más complejos del lenguaje natural. 

Si $w=w_1w_2\cdots w_N$ es una frase, y las $w$ representan palabras, recordemos que un modelo de lenguaje con dependencia de $n$-gramas consiste de las probabilidades

$$P(w_t | w_{t-1} w_{t-2} \cdots w_{t-n+1}),$$

 (n=2, bigramas, n=3 trigramas, etc.)

Y vimos que tenemos problemas cuando observamos sucesiones que no vimos en el corpus de entrenamiento. Este problema se puede "parchar" utilizando técnicas de suavizamiento. Aún para colecciones de entrenamiento muy grandes tenemos que lidiar con este problema.

Podemos tomar un enfoque más estructurado pensando en representaciones "distribucionales" de palabras:

1. Asociamos a cada palabra en el vocabulario un vector numérico con $d$ dimensiones, que es su *representación distribuida*.
2. Expresamos la función de probabilidad como combinaciones de 
las representaciones vectoriales del primer paso.
3. Aprendemos (máxima verosimiltud posiblemente regularización) simultáneamente los vectores y la manera de combinar 
estos vectores para producir probabilidades.

 La idea de este modelo es entonces subsanar la relativa escasez de datos (comparado con todos los trigramas que pueden existir) con estructura. Sabemos que esta es una buena estrategia si la estrucutura impuesta es apropiada.

\BeginKnitrBlock{resumen}<div class="resumen">Una de las ideas fundamentales de este enfoque es representar
a cada palabra como un vector numérico de dimensión $d$. Esto
se llama una *representación vectorial distribuida*, o también
un *embedding de palabras*.</div>\EndKnitrBlock{resumen}

El objeto es entonces abstraer características de palabras (mediante estas representaciones) 
intentando no perder mucho de su sentido
original, lo que nos permite conocer palabras por su contexto, aún cuando no las hayamos observado antes.


### Ejemplo {-}

¿Cómo puede funcionar este enfoque? Por ejemplo, si vemos la frase "El gato corre en el jardín", sabemos que una frase probable debe ser también "El perro corre en el jardín", pero quizá nunca vimos en el corpus la sucesión "El perro corre". La idea es que como "perro" y "gato" son funcionalmente similares (aparecen en contextos similares en otros tipos de oraciones como el perro come, el gato come, el perro duerme, este es mi gato, etc.), un modelo como el de arriba daría vectores similares a "perro" y "gato", pues aparecen en contextos similares. Entonces el modelo daría una probabilidad alta a "El perro corre en el jardín".

## Modelo de red neuronal

Podemos entonces construir una red neuronal con 2 capas ocultas como sigue (segimos [@bengio], una de
las primeras referencias en usar este enfoque). Usemos el ejemplo de trigramas:

1. **Capa de incrustación o embedding**. En la primera capa oculta, tenemos un mapeo de las entradas $w_1,\ldots, w_{n-1}$ a $x=C(w_1),\ldots, C(w_{n-1})$, donde $C$ es una función que mapea palabras a vectores de dimensión $d$. $C$ también se puede pensar como una matriz de dimensión $|V|$ por $d$. En la capa de entrada,

$$w_{n-2},w_{n-1} \to x = (C(w_{n-2}), C(w_{n-1})).$$


2. **Capa totalmente conexa**. En la siguiente capa oculta tenemos una matriz de pesos $H$ y la función logística (o tangente hiperbólica) $\sigma (z) = \frac{e^z}{1+e^z}$, como en una red neuronal usual. 

En esta capa calculamos
$$z = \sigma (a + Hx),$$
que resulta en un vector de tamaño $h$. 

3. La **capa de salida** debe ser un vector de probabilidades
sobre todo el vocabulario $|V|$. En esta capa tenemos pesos $U$ y hacemos
$$y = b + U\sigma (z),$$
y finalmente usamos softmax para tener probabilidades que suman uno:
$$p_i = \frac{\exp (y_i) }{\sum_j exp(y_j)}.$$

En el ajuste maximizamos la verosimilitud:

$$\sum_t \log \hat{P}(w_{t,n}|w_{t,n-2}w_{t-n-1}) $$ 



La representación en la referencia [@bengio] es:

![Imagen](images/1_neural_model.png)

Esta idea original ha sido explotada con éxito, aunque sigue siendo
intensivo en cómputo ajustar un modelo como este. Nótese que
el número de parámetros es del orden de $|V|(nm+h)$, donde $|V|$ es el tamaño del vocabulario (decenas o cientos de miles), $n$ es 3 o 4 (trigramas, 4-gramas), $m$ es el tamaño de la representacion (cientos) y $h$ es el número de nodos en la segunda capa (también cientos o miles).  Esto resulta en el mejor de los casos en modelos con miles de millones de parámetros. Adicionalmente, hay algunos cálculos costosos, como el softmax (donde hay que hacer una suma sobre el vocabulario completo). En el paper original se propone **descenso estocástico**.


### Ejemplo {-}
Veamos un ejemplo chico de cómo se vería el paso
feed-forward de esta red. Supondremos en este
ejemplo que los sesgos $a,b$ son
iguales a cero para simplificar los cálculos.

Consideremos que el texto de entrenamiento es
"El perro corre. El gato corre. El león corre. El león ruge."

En este caso, nuestro vocabulario consiste de los 8 tokens
$<s>$, el, perro, gato, león, corre, caza $</s>$. Consideremos un
modelo con $d=2$ (representaciones de palabras en 2 dimensiones),
y consideramos un modelo de trigramas.

Nuestra primera capa es una matriz $C$ de tamaño $2\times 8$,
es decir, un vector de tamaño 2 para cada palabra. Por ejemplo,
podríamos tener

```r
library(tidyverse)
set.seed(63)
C <- round(matrix(rnorm(16, 0, 0.1), 2, 8), 2)
colnames(C) <- c("_s_", "el", "perro", "gato", "león", "corre", "caza", "_ss_")
rownames(C) <- c("d_1", "d_2")
C
```

```
##       _s_    el perro gato  león corre caza  _ss_
## d_1  0.13  0.05  0.05 0.04 -0.17  0.04 0.03 -0.02
## d_2 -0.19 -0.19 -0.11 0.01  0.04 -0.01 0.02  0.02
```

En la siguiente capa consideremos que usaremos, arbitrariamente, $h=3$ unidades. Como estamos considerando bigramas, necesitamos una entrada de tamaño 4 (representación de un bigrama, que son dos vectores de la matriz $C$, para predecir la siguiente palabra).


```r
H <- round(matrix(rnorm(12, 0, 0.1), 3, 4), 2)
H
```

```
##       [,1]  [,2]  [,3]  [,4]
## [1,] -0.04  0.12 -0.09  0.18
## [2,]  0.09  0.10  0.06  0.08
## [3,]  0.10 -0.08 -0.07 -0.13
```

Y la última capa es la del vocabulario. Son entonces 8 unidades,
con 3 entradas cada una. La matriz de pesos es:


```r
U <- round(matrix(rnorm(24, 0, 0.1), 8, 3), 2)
rownames(U) <- c("_s_", "el", "perro", "gato", "león", "corre", "caza", "_ss_")
U
```

```
##        [,1]  [,2]  [,3]
## _s_    0.05 -0.15 -0.30
## el     0.01  0.16  0.15
## perro -0.14  0.10  0.05
## gato   0.04  0.09  0.12
## león   0.06 -0.03  0.02
## corre -0.01  0.00 -0.02
## caza   0.10  0.00  0.06
## _ss_   0.07 -0.10  0.01
```

Ahora consideremos cómo se calcula el objetivo con los
datos de entrenamiento. El primer trigrama es (\_s\_, el). La primera
capa entonces devuelve los dos vectores correspondientes a cada
palabra (concatenado):


```r
capa_1 <- c(C[, "_s_"], C[, "el"])
capa_1
```

```
##   d_1   d_2   d_1   d_2 
##  0.13 -0.19  0.05 -0.19
```

La siguiente capa es:


```r
sigma <- function(z){ 1 / (1 + exp(-z))}
capa_2 <- sigma(H %*% capa_1)
capa_2
```

```
##           [,1]
## [1,] 0.4833312
## [2,] 0.4951252
## [3,] 0.5123475
```

Y la capa final da


```r
y <- U %*% capa_2
y
```

```
##               [,1]
## _s_   -0.203806461
## el     0.160905460
## perro  0.007463525
## gato   0.125376210
## león   0.024393066
## corre -0.015080262
## caza   0.079073967
## _ss_  -0.010555858
```

Y aplicamos softmax para encontrar las probabilidades


```r
p <- exp(y)/sum(exp(y)) |> as.numeric()
p
```

```
##             [,1]
## _s_   0.09931122
## el    0.14301799
## perro 0.12267376
## gato  0.13802588
## león  0.12476825
## corre 0.11993917
## caza  0.13178067
## _ss_  0.12048306
```

Y la probabilidad es entonces


```r
p_1 <- p["perro", 1]
p_1
```

```
##     perro 
## 0.1226738
```

Cuya log probabilidad es


```r
log(p_1)
```

```
##     perro 
## -2.098227
```

Ahora seguimos con el siguiente trigrama, que
es "(perro, corre)". Necesitamos calcular la probabilidad
de corre dado el contexto "el perro". Repetimos nuestro cálculo:


```r
capa_1 <- c(C[, "perro"], C[, "corre"])
capa_1
```

```
##   d_1   d_2   d_1   d_2 
##  0.05 -0.11  0.04 -0.01
```

```r
capa_2 <- sigma(H %*% capa_1)
capa_2
```

```
##           [,1]
## [1,] 0.4948502
## [2,] 0.4987750
## [3,] 0.5030750
```

```r
y <- U %*% capa_2
y
```

```
##               [,1]
## _s_   -0.200996230
## el     0.160213746
## perro  0.005752223
## gato   0.125052753
## león   0.024789260
## corre -0.015010001
## caza   0.079669516
## _ss_  -0.010207238
```

```r
p <- exp(y)/sum(exp(y)) |> as.numeric()
p
```

```
##             [,1]
## _s_   0.09958028
## el    0.14290415
## perro 0.12245121
## gato  0.13796681
## león  0.12480464
## corre 0.11993506
## caza  0.13184539
## _ss_  0.12051246
```

Y la probabilidad es entonces


```r
p_2 <- p["corre", 1]
log(p_2)
```

```
##     corre 
## -2.120805
```

Sumando, la log probabilidad es:


```r
log(p_1) + log(p_2)
```

```
##     perro 
## -4.219032
```

y continuamos con los siguientes trigramas del texto de entrenamiento.
Creamos una función


```r
feed_fow_p <- function(trigrama, C, H, U){
  trigrama <- strsplit(trigrama, " ", fixed = TRUE)[[1]]
  capa_1 <- c(C[, trigrama[1]], C[, trigrama[2]])
  capa_2 <- sigma(H %*% capa_1)
  y <- U %*% capa_2
  p <- exp(y)/sum(exp(y)) |> as.numeric()
  p
}

feed_fow_dev <- function(trigrama, C, H, U) {
  p <- feed_fow_p(trigrama, C, H, U)
  trigrama_s <- strsplit(trigrama, " ", fixed = TRUE)[[1]]
  log(p)[trigrama_s[3], 1]
}
```

Y ahora aplicamos a todos los textos:


```r
texto_entrena <- c("_s_ el perro corre _ss_", " _s_ el gato corre _ss_", " _s_ el león corre _ss_",
  "_s_ el león caza _ss_",  "_s_ el gato caza _ss_")
entrena_trigramas <- map(texto_entrena, 
  ~tokenizers::tokenize_ngrams(.x, n = 3)[[1]]) |> 
  flatten() |> unlist()
entrena_trigramas
```

```
##  [1] "_s_ el perro"     "el perro corre"   "perro corre _ss_" "_s_ el gato"     
##  [5] "el gato corre"    "gato corre _ss_"  "_s_ el león"      "el león corre"   
##  [9] "león corre _ss_"  "_s_ el león"      "el león caza"     "león caza _ss_"  
## [13] "_s_ el gato"      "el gato caza"     "gato caza _ss_"
```


```r
log_p <- sapply(entrena_trigramas, function(x) feed_fow_dev(x, C, H, U))
sum(log_p)
```

```
## [1] -31.21475
```

Ahora piensa como harías más grande esta verosimilitud. Observa
que "perro", "gato" y "león"" están comunmente seguidos de "corre".
Esto implica que nos convendría que hubiera cierta similitud
entre los vectores de estas tres palabras, por ejemplo:


```r
C_1 <- C
indices <- colnames(C) %in%  c("perro", "gato", "león")
C_1[1, indices] <- 3.0
C_1[1, !indices] <- -1.0
C_1
```

```
##       _s_    el perro gato león corre  caza  _ss_
## d_1 -1.00 -1.00  3.00 3.00 3.00 -1.00 -1.00 -1.00
## d_2 -0.19 -0.19 -0.11 0.01 0.04 -0.01  0.02  0.02
```

La siguiente capa queremos que extraiga el concepto "animal" en la palabra anterior, o algo
similar, así que podríamos poner en la unidad 1:


```r
H_1 <- H
H_1[1, ] <- c(0, 0, 5, 0)
H_1
```

```
##      [,1]  [,2]  [,3]  [,4]
## [1,] 0.00  0.00  5.00  0.00
## [2,] 0.09  0.10  0.06  0.08
## [3,] 0.10 -0.08 -0.07 -0.13
```

Nótese que la unidad 1 de la segunda capa se activa 
cuando la primera componente de la palabra anterior es alta.
En la última capa, podríamos entonces poner


```r
U_1 <- U
U_1["corre", ] <- c(4.0, -2, -2)
U_1["caza", ] <- c(4.2, -2, -2)
U_1
```

```
##        [,1]  [,2]  [,3]
## _s_    0.05 -0.15 -0.30
## el     0.01  0.16  0.15
## perro -0.14  0.10  0.05
## gato   0.04  0.09  0.12
## león   0.06 -0.03  0.02
## corre  4.00 -2.00 -2.00
## caza   4.20 -2.00 -2.00
## _ss_   0.07 -0.10  0.01
```

que captura cuando la primera unidad se activa. Ahora el cálculo
completo es:


```r
log_p <- sapply(entrena_trigramas, function(x) feed_fow_dev(x, C_1, H_1, U_1))
sum(log_p)
```

```
## [1] -23.53883
```

Y logramos aumentar la verosimilitud considerablemente. Compara las probabilidades:


```r
feed_fow_p("el perro", C, H, U)
```

```
##             [,1]
## _s_   0.09947434
## el    0.14292280
## perro 0.12256912
## gato  0.13797317
## león  0.12479193
## corre 0.11994636
## caza  0.13180383
## _ss_  0.12051845
```

```r
feed_fow_p("el perro", C_1, H_1, U_1)
```

```
##             [,1]
## _s_   0.03493901
## el    0.04780222
## perro 0.03821035
## gato  0.04690264
## león  0.04308502
## corre 0.33639351
## caza  0.41087194
## _ss_  0.04179531
```

```r
feed_fow_p("el gato", C, H, U)
```

```
##             [,1]
## _s_   0.09957218
## el    0.14289131
## perro 0.12246787
## gato  0.13795972
## león  0.12480659
## corre 0.11993921
## caza  0.13183822
## _ss_  0.12052489
```

```r
feed_fow_p("el gato", C_1, H_1, U_1)
```

```
##             [,1]
## _s_   0.03489252
## el    0.04769205
## perro 0.03813136
## gato  0.04679205
## león  0.04298749
## corre 0.33663831
## caza  0.41117094
## _ss_  0.04169529
```


**Observación**: a partir de este principio, es posible construir arquitecturas más 
refinadas que tomen en cuenta, por ejemplo,  relaciones más lejanas entre
partes de oraciones (no solo el contexto del n-grama), ver por ejemplo [el capítulo 10 del libro
de Deep Learning de Goodfellow, Bengio y Courville](https://www.deeplearningbook.org/contents/rnn.html).

Abajo exploramos una parte fundamental de estos modelos: representaciones de palabras, y modelos
relativamente simples para obtener estas representaciones.

## Representación de palabras

Un aspecto interesante de el modelo de arriba es que
nos da una representación vectorial de las palabras, en la forma
de los parámetros ajustados de la matriz $C$. Esta se puede entender
como una descripción numérica de cómo funciona una palabra en el contexto de su n-grama.

Por ejemplo, deberíamos encontrar que palabras como "perro" y "gato" tienen representaciones similares. La razón es que cuando aparecen,
las probabilidades sobre las palabras siguientes deberían ser similares, pues estas son dos palabras que se pueden usar en muchos contextos
compartidos.

También podríamos encontrar que palabras como perro, gato, águila, león, etc. tienen partes o entradas similares en sus vectores de representación, que es la parte que hace que funcionen como "animal mamífero" dentro de frases. 

Veremos que hay más razones por las que es interesante esta representación.


## Modelos de word2vec

Si lo que principalmente nos interesa es obtener la representación
vectorial de palabras, más recientemente se descubrió que es posible 
simplificar considerablemente el modelo de arriba para poder entrenarlo mucho más rápido, y obtener una representación que en muchas tareas se desempeña bien ([@word2vec]).

Hay dos ideas básicas que se pueden usar para reducir la complejidad del entrenamiento (ver más
en [@goodfellow] y [@word2vec]:

- Eliminar la segunda capa oculta: modelo de *bag-of-words* continuo y modelo de *skip-gram*.
- Cambiar la función objetivo (minimizar devianza/maximizar verosimilitud) por una más simple, mediante un truco que se llama *negative sampling*.

Como ya no es de interés central predecir la siguiente palabra a partir
de las anteriores, en estos modelos **intentamos predecir la palabra
central a partir de las que están alrededor**. 

### Arquitectura continuous bag-of-words

La entrada es igual que en el modelo completo. En primer lugar,
simplificamos la segunda capa oculta pondiendo en $z$ el promedio de
los vectores $C(w_{n-2}), C(w_{n-1})$.  La última capa la dejamos igual por el momento:

![Imagen](images/cbow_fig.png)

El modelo se llama bag-of-words porque todas las entradas de la primera capa oculta contribuyen de la misma manera en la salida, independientemente del orden. Aunque esto no suena como buena idea para construir un modelo de lenguaje, veremos que resulta en una representación adecuada para algunos problemas.

1. En la primera capa oculta, tenemos un mapeo de las entradas $w_1,\ldots, w_{n-1}$ a $x=C(w_1),\ldots, C(w_{n-1})$, donde $C$ es una función que mapea palabras a vectores de dimensión $d$. $C$ también se puede pensar como una matriz de dimensión $|V|$ por $d$. En la capa de entrada,

$$w_{n-2},w_{n-1} \to x = (C(w_{n-2}), C(w_{n-1})).$$


2. En la siguiente "capa" oculta simplemente sumamos las entradas de $x$. Aquí nótese que realmente no hay parámetros.

3. Finalmente, la capa de salida debe ser un vector de probabilidades
sobre todo el vocabulario $|V|$. En esta capa tenemos pesos $U$ y hacemos
$$y = b + U\sigma (z),$$
y finalmente usamos softmax para tener probabilidades que suman uno:
$$p_i = \frac{\exp (y_i) }{\sum_j exp(y_j)}.$$

En el ajuste maximizamos la verosimilitud sobre el corpus. Por ejemplo, para una frase, su log verosimilitud es:

$$\sum_t \log \hat{P}(w_{t,n}|w_{t,n+1} \cdots w_{t-n-1}) $$

### Arquitectura skip-grams

Otro modelo simplificado, con más complejidad computacional pero
mejores resultados (ver [@word2vec]) que
el bag-of-words, es el modelo de skip-grams. En este caso, dada
cada palabra que encontramos, intentamos predecir un número
fijo de las palabras anteriores y palabras posteriores 
(el contexto es una vecindad de la palabra).

![Imagen](images/skipgram.png)


La función objetivo se defina ahora (simplificando) como suma sobre $t$:

$$-\sum_t \sum_{ -2\leq j \leq 2, j\neq 0} \log P(w_{t-j} | w_t)$$
(no tomamos en cuenta dónde aparece exactamente $w_{t-j}$ en relación a $w_t$, simplemente consideramos que está en su contexto),
donde

$$\log P(w_{t-j}|w_t) =  u_{t-j}^tC(w_n) - \log\sum_k \exp{u_{k}^tC(w_n)}$$

Todavía se propone una simplificación adicional que resulta ser efectiva:

### Muestreo negativo

La siguiente simplificación consiste en cambiar la función objetivo. En word2vec puede usarse "muestreo negativo".

Para empezar, la función objetivo original (para contexto de una sola palabra) es


$$E = -\log \hat{P}(w_{a}|w_{n}) = -y_{w_a} + \log\sum_j \exp(y_j),$$

donde las $y_i$ son las salidas de la penúltima capa. La dificultad está en el segundo término, que es sobre todo el vocabulario en incluye todos los parámetros del modelo (hay que calcular las parciales de $y_j$'s
sobre cada una de las palabras del vocabulario).


La idea del muestreo negativo es que si $w_a$ 
está en el contexto de $w_{n}$, tomamos una muestra de $k$ palabras
$v_1,\ldots v_k$ al azar
(2-50, dependiendo del tamaño de la colección), y creamos $k$
"contextos falsos" $v_j w_{n}$, $j=1\ldots,k$. Minimizamos
en lugar de la observación de arriba

$$E = -\log\sigma(y_{w_a}) + \sum_{j=1}^k \log\sigma(y_j),$$
en donde queremos maximizar la probabilidad de que ocurra
$w_a$ vs. la probabilidad de que ocurra alguna de las $v_j$.
Es decir, solo buscamos optimizar parámetros para separar lo mejor
que podamos la observación de $k$ observaciones falsas, lo cual implica que tenemos que mover un número relativamente chico de
parámetros (en lugar de todos los parámetros de todas las palabras del vocabulario). 

Las palabras "falsas" se escogen según una probabilidad ajustada
de unigramas (se observó empíricamente mejor desempeño cuando escogemos cada palabra con probabilidad proporcional a $P(w)^{3/4}$, en lugar de $P(w)$, ver [@word2vec]).


### Ejemplo {-}


```r
install.packages("word2vec")
library(word2vec)
```


```r
library(tidyverse)
ruta <- "../datos/noticias/ES_Newspapers.txt"
if(!file.exists(ruta)){
    periodico <- 
      read_lines(file= "https://es-noticias.s3.amazonaws.com/Es_Newspapers.txt",
                        progress = FALSE)
    write_lines(periodico, ruta)
} else {
    periodico <- read_lines(file= ruta,
                        progress = FALSE)
}
normalizar <- function(texto, vocab = NULL){
  # minúsculas
  texto <- tolower(texto)
  # varios ajustes
  texto <- gsub("\\s+", " ", texto)
  texto <- gsub("\\.[^0-9]", " _punto_ ", texto)
  texto <- gsub(" _s_ $", "", texto)
  texto <- gsub("\\.", " _punto_ ", texto)
  texto <- gsub("[«»¡!¿?-]", "", texto) 
  texto <- gsub(";", " _punto_coma_ ", texto) 
  texto <- gsub("\\:", " _dos_puntos_ ", texto) 
  texto <- gsub("\\,[^0-9]", " _coma_ ", texto)
  texto <- gsub("\\s+", " ", texto)
  texto
}
periodico_df <- tibble(txt = periodico) |>
                mutate(id = row_number()) |>
                mutate(txt = normalizar(txt))
```


Construimos un modelo con vectores de palabras de tamaño 50,
skip-grams de tamaño 6, y ajustamos con muestreo negativo
de tamaño 5:


```r
modelo <- word2vec(x = periodico_df$txt, type = "skip-gram", iter = 10, 
                   dim = 50, window = 6L, negative = 10L, 
                   threads = 8L, sample = 0.005, min_count = 20)
write.word2vec(modelo, file = "./salidas/noticias_vectors.bin")
```


```r
modelo <- read.word2vec("./salidas/noticias_vectors.bin")
```


El resultado son los vectores aprendidos de las palabras, por ejemplo


```r
vector_gol <- predict(modelo, "gol", type = "embedding")
vector_gol |> as.numeric()
```

```
##  [1]  0.092273168  1.024451613 -0.282050163  0.859585762 -1.542793036
##  [6]  0.858215690 -0.898579419  0.037183136  2.892853737 -0.374552220
## [11] -0.975951195 -1.131990314 -0.362287104 -1.669579029  0.108412631
## [16] -0.538423538 -0.795996606 -1.084180832 -0.788449764 -2.239182949
## [21] -0.260846645  0.218292192 -0.316080689  1.115552664 -0.689553678
## [26] -0.654445112 -0.556519449 -0.078940324  0.984561563  0.405610383
## [31]  0.187591910  1.436592817  1.995020747  0.827492654  0.170227647
## [36]  0.991732061  0.141226083  0.049184673  0.003126387 -1.380208850
## [41]  1.269512534 -0.639893711 -1.288470984 -0.381622076 -0.059291609
## [46] -0.259091765  0.184948400  0.471573681  0.682058871  2.157181025
```

## Espacio de representación de palabras {#esprep}

Como discutimos arriba, palabras que se usan en contextos
similares por su significado o por su función (por ejemplo, "perro" y "gato"") deben tener representaciones similares, pues su contexto tiende a ser similar. **La similitud que usamos el similitud coseno**.

Podemos verificar con nuestro ejemplo:



```r
predict(modelo, newdata = c("gol"), type = "nearest", top_n = 5)
```

```
## $gol
##   term1   term2 similarity rank
## 1   gol  empate  0.9516754    1
## 2   gol  golazo  0.9484443    2
## 3   gol penalti  0.9408622    3
## 4   gol  remate  0.9222239    4
## 5   gol   saque  0.9205684    5
```

Otros ejemplos:


```r
palabras <- c("lluvioso", "parís", "cinco")
predict(modelo, newdata = palabras, type = "nearest", top_n = 4) |> 
  bind_rows() |> knitr::kable()
```



|term1    |term2    | similarity| rank|
|:--------|:--------|----------:|----:|
|lluvioso |húmedo   |  0.8911762|    1|
|lluvioso |frío     |  0.8517610|    2|
|lluvioso |invierno |  0.8413799|    3|
|lluvioso |caluroso |  0.8314730|    4|
|parís    |londres  |  0.9698847|    1|
|parís    |roma     |  0.9339487|    2|
|parís    |berlín   |  0.9334224|    3|
|parís    |viena    |  0.9314210|    4|
|cinco    |seis     |  0.9918947|    1|
|cinco    |cuatro   |  0.9897406|    2|
|cinco    |siete    |  0.9881529|    3|
|cinco    |tres     |  0.9850138|    4|

Donde vemos, por ejemplo, que el modelo puede capturar conceptos relacionados
con el estado del clima, capitales de países y números - aún cuando no hemos
anotado estas funciones en el corpus original. Estos vectores son similares
porque tienden a ocurrir en contextos similares.

### Geometría en el espacio de representaciones {-}

Ahora consideremos cómo se distribuyen las palabras en este
espacio, y si existe estructura geométrica en este espacio que tenga
información acerca del lenguaje.

Consideremos primero el caso de plurales de sustantivos.

- Como el contexto de los plurales es distinto de los singulares,
nuestro modelo debería poder capturar en los vectores su diferencia.
- Examinamos entonces cómo son geométricamente
diferentes las representaciones de plurales vs singulares
- Si encontramos un patrón reconocible, podemos utilizar este patrón, por ejemplo,
para encontrar la versión plural de una palabra singular, *sin usar ninguna
regla del lenguaje*.

Una de las relaciones geométricas más simples es la adición de vectores. Por ejemplo,
extraemos la diferencia entre gol y goles:


```r
emb <- as.matrix(modelo)
# del concepto de días, quitarle día: "queda" el plural
plural_1 <- emb["días", ] - emb["día", ]
plural_2 <- emb["goles", ] - emb["gol", ]
plural_3 <- emb["tíos", ] - emb["tío", ]
plural <- (plural_1 + plural_2 + plural_3) / 3
plural
```

```
##  [1]  0.0152804628  0.1377313354 -0.3195977906  0.0177193433 -0.1054255466
##  [6]  0.0759639492 -0.0539081891  0.4265168334 -1.0973842889  0.7582209806
## [11]  0.1083961229  0.7251005520  0.4841281871  0.6509703398  0.0717903599
## [16]  1.2221822987 -0.6148995658  0.4453237057 -0.1102930208  0.6098377009
## [21] -0.5223372926  0.6567373524 -0.1752699489  1.6437549790 -0.9586302688
## [26] -0.3756186937  1.4757740299 -0.2220435285 -0.1646723300 -0.4038018634
## [31] -0.7867156826 -0.3250945499 -0.9661249717  1.3409692347  0.0724218885
## [36]  1.3712943097 -0.2274952332  0.3894831166 -0.3254537137 -0.0052393774
## [41] -0.0003958195 -0.6526739920  0.4897470673  0.4023401837  0.8496992812
## [46]  0.2727282254 -0.9253207197  0.0072911481  0.0636507695 -0.6696523329
```

que es un vector en el espacio de representación de palabras. Ahora sumamos este vector
a un sustantivo en singular, y vemos qué palabras están cercas de esta "palabra sintética". 


```r
vector <- emb["partido",]  + plural
predict(modelo, newdata = vector, type = "nearest", top_n = 5)
```

```
##         term similarity rank
## 1   partidos  0.9544303    1
## 2    partido  0.8980539    2
## 3     derbis  0.8895127    3
## 4   ligueros  0.8698068    4
## 5 encuentros  0.8686123    5
```
Nótese que entre las más cercanas está justamente el plural correcto, o otros plurales con relación
al que buscábamos.

Otro ejemplo:


```r
predict(modelo, newdata = emb["mes", ] + plural, 
        type = "nearest", top_n = 5)
```

```
##         term similarity rank
## 1        mes  0.9219741    1
## 2      meses  0.9001195    2
## 3      junio  0.8886548    3
## 4 septiembre  0.8859831    4
## 5       2009  0.8830921    5
```
Ahora veamos por ejemplo el género:


```r
fem_2 <- emb["mujer", ] - emb["hombre", ]
predict(modelo, newdata = emb["presidente", ] + fem_2, 
        type = "nearest", top_n = 5)
```

```
##             term similarity rank
## 1     presidenta  0.9603671    1
## 2     presidente  0.9528462    2
## 3 vicepresidenta  0.9294355    3
## 4    presidencia  0.9128675    4
## 5     secretaria  0.9072133    5
```

```r
predict(modelo, newdata = emb["rey", ] + fem_2, 
        type = "nearest", top_n = 5)
```

```
##       term similarity rank
## 1      rey  0.9483816    1
## 2    reina  0.9384007    2
## 3 majestad  0.9177670    3
## 4 princesa  0.9173969    4
## 5  infanta  0.9131138    5
```

También podemos probar intentar contestar preguntas de analogía, por ejemplo

- Francia es a París como Inglaterra es a ...



```r
rusia_moscu <- emb["rusia", ] - emb["moscú", ]
paris_francia <- emb["francia", ] - emb["parís", ]
pais <- (rusia_moscu + paris_francia) / 2
#despejamos: madrid_es_a_españa <- emb["madrid", ] - emb["españa", ] y obtenemos:
inglaterra_es_a_x <- emb["inglaterra", ] - pais
predict(modelo, inglaterra_es_a_x, type = "nearest", top_n = 5)
```

```
##         term similarity rank
## 1    londres  0.9953559    1
## 2 inglaterra  0.9830307    2
## 3      parís  0.9820109    3
## 4      miami  0.9706251    4
## 5   shanghai  0.9584799    5
```




