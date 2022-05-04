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
modelo <- word2vec(x = periodico_df$txt, type = "skip-gram", 
                   dim = 100, window = 6L, negative = 20L, threads = 4L)
```



El resultado son los vectores aprendidos de las palabras, por ejemplo


```r
incrustacion <- as.matrix(modelo)
incrustacion["gol", ] 
```

```
##   [1]  0.32225347  0.29010415  0.56430739 -1.26586449 -0.01668300 -1.08759964
##   [7] -0.35996071 -0.88176644  1.20925879 -1.27710402  1.96568203 -0.08576190
##  [13] -0.77409923 -0.77821970  0.07314577  0.40722370  0.61932373 -0.99852824
##  [19] -0.26369676 -0.87080562  0.92050624  0.13246848 -1.65784192 -0.75884891
##  [25] -1.17742312 -1.18703151 -0.30562764 -0.26037884 -1.14858460 -0.41433176
##  [31] -0.59770387  1.00164127  1.03174484  1.38414884  0.10544349  0.39592695
##  [37]  0.43748003 -0.95137733 -0.20493250 -0.71881706 -0.38461855  0.18196182
##  [43] -0.78369427 -0.03154339 -0.72078013  0.63540888  0.50101852 -0.01853132
##  [49]  1.02588809 -0.35365176  1.29695368 -0.07013670  0.60798782 -1.84792352
##  [55] -0.33396369  0.68478417  0.86970586 -1.70703113 -1.74008381  0.74598628
##  [61] -0.33810931 -0.31248233 -0.57892632  0.13759825  1.22563362 -0.09651208
##  [67]  0.38890716  0.04135910 -1.87075281  0.56047046  1.27442420  0.66101581
##  [73] -2.00741887  1.51594436 -0.20256953  0.48299745  0.39481014 -0.01258742
##  [79] -1.57995033 -0.19682033  1.00979435 -1.11899686  0.21027224  0.48242337
##  [85] -1.47033298  0.05368399 -0.81877607 -0.63951886 -1.12013686  0.68263984
##  [91]  4.36106873 -0.83029497  1.86541545 -0.92819768  0.63164508  1.03381801
##  [97] -0.04038213  0.02635830  1.88781822 -0.01920896
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
## 1   gol  empate  0.9173362    1
## 2   gol  golazo  0.9166898    2
## 3   gol penalti  0.9106060    3
## 4   gol   goles  0.9006565    4
## 5   gol empatar  0.8898841    5
```

También podemos buscar varias palabras:


```r
palabras <- c("soleado","lluvioso")
predict(modelo, newdata = palabras, type = "nearest", top_n = 5)
```

```
## $soleado
##     term1     term2 similarity rank
## 1 soleado fresquito  0.8455517    1
## 2 soleado    gélido  0.8353294    2
## 3 soleado      frío  0.8274860    3
## 4 soleado   nublado  0.8169536    4
## 5 soleado  amanecía  0.8166083    5
## 
## $lluvioso
##      term1    term2 similarity rank
## 1 lluvioso   húmedo  0.9044551    1
## 2 lluvioso lluviosa  0.8369184    2
## 3 lluvioso     nevó  0.8222449    3
## 4 lluvioso     frío  0.8218763    4
## 5 lluvioso caluroso  0.8118451    5
```

Ahora consideremos cómo se distribuyen las palabras en este
espacio, y si existe estructura geométrica en este espacio.

Consideremos primero el caso de plurales de sustantivos.

- Como el contexto de los plurales es distinto de los singulares,
nuestro modelo puede capturar en los vectores su diferencia.
- Examinamos entonces cómo son geométricamente
diferentes las representaciones de plurales vs singulares
- Si encontramos un patrón reconocible, podemos utilizar este patrón, por ejemplo,
para encontrar la versión plural de una palabra singular, *sin usar ninguna
regla del lenguaje*.

Una de las relaciones geométricas más simples es la adición de vectores. Por ejemplo,
extraemos la diferencia entre gol y goles:


```r
plural_1 <- incrustacion["goles", ] - incrustacion["gol",]
plural_1
```

```
##   [1] -0.41010650 -0.09367068  0.10013825 -0.01043606 -0.69925217  0.63240004
##   [7] -1.25355980 -0.25786495 -0.30724758 -0.62970757 -0.86795354 -0.33097465
##  [13]  0.63819146  0.89995096  0.80200664 -0.96015745 -0.88044503  0.73197424
##  [19]  0.37708700  0.35302806  0.76635766  0.73995791  0.63460803 -0.66580033
##  [25]  0.62375081 -0.97293353 -0.04242826 -0.45898974  0.39994091  0.30355571
##  [31] -0.28930634 -0.59067285  0.81816709  0.47144985  0.54982828  0.05406371
##  [37]  0.15333903  0.83845954 -0.49170966  0.29262483  1.57328549  0.82192166
##  [43] -0.39690197  0.70654460  0.14798385 -0.43928348 -0.27604572  0.20851085
##  [49] -0.11255991 -0.68816626 -0.66432583  0.05098183 -0.32413444 -0.51244164
##  [55]  0.34192570  0.01833647  0.24682266  0.66435456 -0.65305912  0.22694319
##  [61]  0.25811008 -0.07838404 -0.29997021 -0.73384967  0.10233676  0.84096706
##  [67]  0.07619473 -0.18465022  0.53090453 -0.61795783  0.45793355 -0.46914509
##  [73]  1.18731731 -0.84401566 -0.63708998  0.47073039  0.38214815 -0.71852392
##  [79]  1.11701551  1.14750899  0.06465220 -0.48419011  0.32698645  0.18334156
##  [85]  0.95642942 -1.16262745 -0.10756570  1.09330720 -0.22378445  0.21736056
##  [91] -1.35571718  0.10313135 -0.38550878 -0.85293561  0.22138959 -0.19883955
##  [97] -0.42324607  0.41782234 -0.77964056  0.28357970
```

que es un vector en el espacio de representación de palabras. Ahora sumamos este vector
a un sustantivo en singular, y vemos qué palabras están cercas de esta "palabra sintética":


```r
vector <- incrustacion["partido",] + plural_1
predict(modelo, newdata = vector, type = "nearest", top_n = 5)
```

```
##         term similarity rank
## 1    partido  0.9500611    1
## 2   partidos  0.8834544    2
## 3     kassab  0.8493576    3
## 4      goles  0.8284315    4
## 5 encuentros  0.8136083    5
```

Nótese que entre las más cercanas está justamente el plural correcto, o otros plurales con relación
al que buscábamos.

Otro ejemplo:

