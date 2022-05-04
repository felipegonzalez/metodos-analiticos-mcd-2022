# Modelos de lenguaje y n-gramas

Los **modelos de lenguaje** son
una parte fundamental de varias tareas de NLP (procesamiento de
lenguaje natural), como reconocimiento de lenguaje hablado, 
reconocimiento de lenguaje escrito, traducción automática, 
corrección de ortografía, sistemas de predicción de escritura,
etc. (ver [@jurafsky], capítulo 4, o en la nueva edición
el [capítulo 3](https://web.stanford.edu/~jurafsky/slp3/3.pdf)
).


\BeginKnitrBlock{resumen}<div class="resumen">Un **modelo del lenguaje** de tipo estadístico es una asignación de 
probabilidades $P(W)$ a cada posible frase del lenguaje
$W = w_1 w_2 w_3 \cdots w_n$. 
</div>\EndKnitrBlock{resumen}

Estos modelos del lenguaje están diseñados para
resolver distintas tareas particulares y estimar probabilidades particulares
de interés, de modo que hay muchas maneras de entrenar estos modelos.

Comenzaremos por entender métodos básicos para construir estos modelos,
como conteo de *n-gramas*, y consideraremos métodos modernos que se basan
en *representaciones distribuidas*.


## Ejemplo: Modelo de canal ruidoso

El modelo del canal ruidoso muestra una situación general en la que los modelos
del lenguaje son importantes:

\BeginKnitrBlock{resumen}<div class="resumen">**Canal ruidoso**
  
En el modelo del canal ruidoso tratamos mensajes recibidos como si fueran *distorsionados* o transformados al pasar por un canal de comunicación ruidoso (por ejemplo, escribir en el celular).

La tarea que queremos resolver con este modelo es 
**inferir** la palabra o texto correctos a partir de 

- Un modelo de distorsión o transformación (modelo del canal)
- Un modelo del lenguaje.</div>\EndKnitrBlock{resumen}

Ahora veremos por qué necesitamos estas dos partes. Supongamos que recibimos 
un mensaje codificado o transformado $X$ (quizá texto con errores,
o sonido, o una página escrita), y quisiéramos recuperar el mensaje original $W$
(sucesión de palabras en texto). Este problema lo podemos enfocar como sigue:

- Quisiéramos calcular, para cada mensaje **en texto** $W$ la probabilidad

$$P(W|X).$$

Propondríamos entonces como origen el texto $W^*$ que maximiza esta probabilidad condicional:

$$W^* = argmax_W P(W|X),$$

que en principio es un máximo sobre todas las posibles frases del lenguaje.

¿Cómo construimos esta probabilidad condicional? Tenemos que
para cada posible frase $W$,

$$P(W|X) = \frac{P(X|W)P(W)}{P(X)},$$

así que podemos escribir ($X$ es constante)

$$ W^* = argmax_W P(X|W)P(W).$$

Esta forma tiene dos partes importantes:

1. **Verosimilitud**: la probabilidad $P(X|W)$ de observar el mensaje transfromado $X$ dado que el mensaje es $W$. Este es el  **modelo del canal** (o **modelo de errores**), que nos dice cómo ocurren errores o transformaciones $X$ cuando se pretende comunicar el mensaje $W$.

2. **Inicial** o **previa**: La probabilidad $P(W)$ de observar el mensaje $W$ en el contexto actual. Esto depende más del lenguaje que del canal, y le llamamos el **modelo del lenguaje**.

3. Nótese que con estas dos partes tenemos un modelo generativo para mensajes del canal ruidoso: primero seleccionamos un texto mediante el modelo de lenguaje, con las probabilidades $P(W)$, y dado el mensaje
construimos el mensaje recibido según las probabilidades $P(X|W)$.

#### Ejemplos {-}

Supongamos que recibimos el mensaje $X=$"Estoy a días minutos", 
y supongamos que tenemos tres frases en nuestro lenguaje:

$W_1=$"Estoy a veinte minutos", $W_2=$"Estoy a diez minutos", y $W_3$= "No voy a llegar", y $W_4$="Estoy a tías minutos". Supongamos que las probabilidades de cada una, dadas por el modelo de lenguaje, son
(independientemente del mensaje recibido):


|W     |  P(W)|
|:-----|-----:|
|$W_1$ | 1e-03|
|$W_2$ | 1e-03|
|$W_3$ | 8e-03|
|$W_4$ | 1e-06|

Ahora supongamos que el modelo del canal (digamos que sabemos el mecanismo mediante el cual se
escriben los mensajes de texto) nos da:


|W     |  P(W)| P(X&#124;W)|
|:-----|-----:|-----------:|
|$W_1$ | 1e-03|        0.01|
|$W_2$ | 1e-03|        0.12|
|$W_3$ | 8e-03|        0.00|
|$W_4$ | 1e-06|        0.05|

Obsérvese que la probabilidad condicional más alta es la segunda, y en
este modelo es imposible que $W_3$ se transforme en $X$ bajo el canal ruidoso. Multiplicando estas dos probabilidades obtenemos:


|W     |  P(W)| P(X&#124;W)| P(X&#124;W)P(W)|
|:-----|-----:|-----------:|---------------:|
|$W_1$ | 2e-03|        0.01|         0.00002|
|$W_2$ | 1e-03|        0.12|         0.00012|
|$W_3$ | 8e-03|        0.00|         0.00000|
|$W_4$ | 1e-06|        0.05|         0.00000|
de modo que escogeríamos la segunda frase (máxima probabilidad condicional) como la interpretación de
"Estoy a días minutos".

Nótese que $P(X|W_3)$ en particular es muy bajo,
porque es poco posible que el canal distosione "No voy a llegar" 
a "Estoy a días minutos". Por otro lado $P(W_4)$ también
es muy bajo, pues la frase $W_4$ tiene probabilidad muy baja de 
ocurrir.

#### Ejercicio {-}

Piensa cómo sería el modelo de canal ruidoso $P(X|W)$ si nuestro problema fuera reconocimiento de frases habladas o escritas, o en traducción entre dos lenguajes.


## Corpus y vocabulario

En  los ejemplos vistos arriba, vemos que necesitamos definir qué son
las *palabras* $w_i$, qué lenguaje estamos considerando, y cómo estimamos las probabilidades.

\BeginKnitrBlock{comentario}<div class="comentario">- Un **corpus** es una colección de textos (o habla) del lenguaje que nos interesa.
- El **vocabulario** es una colección de palabras que ocurren en el **corpus** (o más general, en el lenguaje).
- La definición de **palabra** (token) depende de la tarea de NLP que nos interesa.</div>\EndKnitrBlock{comentario}

Algunas decisiones que tenemos que tomar, por ejemplo:

- Generalmente, cada palabra está definida como una unidad separada
por espacios o signos de puntuación.
- Los signos de puntuación pueden o no considerarse como palabras.
- Pueden considerarse palabras distintas las que tienen mayúscula y las que no (por ejemplo, para reconocimiento de lenguaje hablado no nos
interesan las mayúsculas).
- Pueden considerarse palabras distintas las que están escritas incorrectamente, o no.
- Pueden considerarse plurales como palabras distintas, formas en masculino/femenino, etc. (por ejemplo, en clasificación de textos quizá
sólo nos importa saber la raíz en lugar de la forma completa de la palabra).
- Comienzos y terminación de oraciones pueden considerarse como
"palabras" (por ejemplo, en reconocimiento de texto hablado).

\BeginKnitrBlock{resumen}<div class="resumen">Al proceso que encuentra todas las palabras en un texto se le
llama **tokenización** o **normalización de texto**. Los **tokens**
de un texto son las ocurrencias en el texto de las palabras
en el vocabuario.</div>\EndKnitrBlock{resumen}

En los ejemplos que veremos a continuación consideraremos las
siguiente normalización:

- Consideramos como una palabra el comienzo y el fin de una oración.
- Normalizamos el texto a minúsculas.
- No corregimos ortografía, y consideramos las palabras en la forma que ocurren.
- Consideramos signos de puntuación como palabras.

El **vocabulario** es el conjunto de todas las palabras posibles en nuestros
textos. Lo denotaremos como $w^1, w^2, \ldots, w^N$, para un vocabulario de $N$ 
distintas palabras o tokens.

## Modelos de lenguaje: n-gramas

Consideremos cómo construiríamos las probabilidades $P(W)$, de manera que
reflejen la ocurrencia de frases en nuestro lenguaje. Escribimos
$$W=w_1 w_2 w_3 \cdots w_n,$$ 
donde $w_i$ son las palabras que contienen el texto $W$.

Aquí nos enfrentamos al primer problema:

- Dada la variedad de frases que potencialmente hay en el lenguaje,
no tiene mucho sentido intentar estimar o enumerar
directamente estas probabilidades. Por ejemplo, si intentamos
algo como intentar ver una colección de ejemplos del lenguaje,
veremos que el número de frases es muy grande, y la mayor
parte de los textos o frases posibles en el lenguaje no
ocurren en nuestra colección (por más grande que sea la
colección).

Para tener un acercamiento razonable, necesitamos considerar
un modelo $P(W)$ con más estructura o supuestos. Hay varias maneras de hacer  esto, 
y un primer acercamiento
consiste en considerar solamente *el contexto más inmediato* de 
cada palabra. Es decir, la probabilidad de ocurrencia de palabras en una frase 
generalmente se puede evaluar con un contexto relativamente
chico (palabras cercanas) y no es necesario considerar la frase completa.

Consideramos entonces la regla del producto:

$$P(w_1 w_2 w_3 \cdots w_n) = P(w_1)P(w_2|w_1)P(w_3|w_1 w_2) \cdots
P(w_n|w_1 w_2 w_3 \cdots w_{n-1})$$
Y observamos entonces que basta con calcular las probabilidades
condicionales de la siguiente palabra:
$$P(w_{m+1}|w_1\cdots w_m)$$
para cualquier conjunto de palabras $w,w_1,\ldots, w_m$. 

A estas $w,w_1,\ldots, w_m$ palabras que ocurren justo antes de $w$ les
llamamos el *contexto* de $w$ en la frase. Por la regla
del producto, podemos ver entonces nuestro problema como uno
de **predecir la palabra siguiente**, dado el contexto. Por ejemplo,
si tenemos la frase "como tengo examen entonces voy a ....", la probabilidad
de observar "estudiar" o "dormir" debe ser más alta que la de "gato".

\BeginKnitrBlock{resumen}<div class="resumen">- A una sucesión de longitud $n$ de palabras $w_1w_2\cdots w_n$ le
llamamos un **n-grama** de nuestro lenguaje.</div>\EndKnitrBlock{resumen}


Igualmente, calcular todas estas condicionales contando tampoco es factible,
pues si el vocabulario es de tamaño $V$, entonces los contextos
posibles son de tamaño $V^m$, el cual es un número muy grande
incluso para $m$ no muy grande. Pero
podemos hacer una simplificación: suponer
que la predicción será suficientemente buena si limitamos el contexto de la siguiente
palabra a $n$-gramas, para una $n$ relativamente chica.

Por ejemplo, para **bigramas**, solo nos interesa calcular
$$P(w_m|w_{m-1}),$$

la dependencia hacia atrás contando solo la palabra anteriore. Simplificaríamos la formula
de arriba como sigue:

$$P(w_1 w_2 w_3 \cdots w_n) = P(w_1)P(w_2|w_1)P(w_3|w_2) P(w_4|w_3)\cdots
P(w_n| w_{n-1})$$

Este se llama modelo basado en **bigramas**. En el caso más simple, establecemos que 
la ocurrencia de una palabra es independiente de su contexto:

$$P(w|w_1\cdots w_{n-1}) = P(w)$$

de forma que el modelo del lenguaje se simplifica a:

$$P(w_1 w_2 w_3 \cdots w_n) = P(w_1)P(w_2)P(w_3) \cdots P(w_n)$$

A este modelo le llamamos el modelo de **unigramas**.

### Modelo generativo de n-gramas

Para que estos modelos den realmente una distribución de probabilidad
sobre todas las frases posibles, es necesario tener también un modelo de la longitud de las frases.
Una manera es definir $P(N)$, que es la distribución sobre la longitud de frase. Sin embargo,
la manera más común es introducir dos símbolos nuevos

- Para inicio de frase usamos $<s>$
- Para fin de frase usamos $</s>$



De esta manera, el proceso de generación de frases en unigramas es el siguiente:

1. Comenzamos con el símbolo $<s>$. 

Comenzando con $i = 1$:

2. Escogemos una palabra $w_i$ del vocabulario $w^1$ a $w^N$ y $</s>$. Estas probabilidades las denotamos como
$P(w^1), P(w^2),\ldots, P(w^N)$ y $P(</s>)$, y todas estas probabilides deben sumar 1.
3. Si escogimos $</s>$, terminamos la frase. En otro caso, regresamos a 2 con $i=i+1$.

La probabilidad de escoger la frase $P(<s>w_1w_2\cdots w_n</s>)$ es entonces

$P(<s>w_1w_2\cdots w_n</s>) = P(w_1)P(w_2)\cdots P(w_n)P(</s>).$

Por construcción, las probabilidades sobre todas las frases suman 1. Necesitamos definir
todas las probabilidades
$$P(w)$$
donde $w$ es una palabra o $</s>$.

#### Ejercicio {-}

Supón que solo hay dos palabras en nuestro vocabulario $a$ y $b$. Calcula cuál es la probabilidad
de obtener una frase de tamaño 1, 2, 3, etc. Verifica que estas probabilidades suman 1. 
(supón que están definidos $p(a),p(b),p(</s>)$ y suman 1).

---

Para **bigramas** el proceso de generación es el siguiente:

1. Comenzamos con el símbolo $<s>$.  
2. Escogemos una palabra $w_1$ según las probabilidades ya definidas 

$$P(w^1|<s>), P(w^2|<s>), \ldots, P(w^N|<s>)$$ 

sobre el vocabulario. Estas probabilidades suman 1.

Comenzando con $i=1$,

3. Escogemos una palabra $w_{i+1}$ según las probabilidades ya definidas 

$$P(w^1|w_i), P(w^2|w_i), \ldots, P(w^N|w_i)$$ 

sobre el vocabulario. Estas probabilidades suman 1.
4. Si la palabra escogida es $</s>$ terminamos. Si no, repetimos 3 con $i=i+1$.


La probabilidad de una frase dada dado el modelo de bigramas es entonces:

$$P(<s>w_1\cdots w_n </s>) = P(w_1|<s>)P(w_2|w_1)P(w_3|w_2)  P(w_4|w_3) \cdots P(w_n|w_{n-1})P(</s>|w_n).$$


Por definición, la suma de probabilidades sobre todas las frases es 1. Necesitamos definir entonces
todas la probablidades
$$p(w|z),$$
donde $z$ es una palabra o $<s>$, y $w$ es una palabra o $</s>$.

Para **trigramas** podemos agregar un símbolo $<s><s>$ al inicio. Esto nos permite definir de manera
simple el proceso de generación como sigue:

1. Comenzamos con los dos símbolos $<s><s>$. 

Comenzando con $i=1$:

2. Cada palabra nueva $w_i$ se escoge según las probabilidades $P(w|w_1w_2)$ sobre $w$ en el vocabulario 
($w^1$, \ldots $w^N$). Estas probabilidades deben sumar uno. 
3. Terminamos cuando la palabra nueva escogida es $</s>$. Si no, repetimos 2 con $i=i+1$

Nótese que en la primera elección escogemos de $p(w|<s><s>)$ y luego de $p(w|<s> w^1)$.


La probabilidad de una frase dada dado el modelo de bigramas es entonces:

$$P(<s><s>w_1\cdots w_n </s>) = P(w_1|<s><s>)P(w_2|<s>w_1)P(w_3|w_1w_2)  P(w_4|w_2w_3) \cdots P(</s>|w_{n-1}w_n).$$



---

El modelo de unigramas
 puede ser deficiente para algunas aplicaciones,
y las probabilidades calculadas con este modelo pueden estar muy
lejos ser razonables. Por ejemplo, el modelo de unigramas da la
misma probabilidad a la frase *un día* y a la frase *día un*, aunque
la ocurrencia en el lenguaje de estas dos frases es muy distinta.

#### Ejemplo{-}
Supongamos que consideramos el modelo de bigramas,  y queremos calcular
la probabilidad de la frase "el perro corre". Agregamos inicio y final
de frase para obtener $<s> el \, perro \, corre </s>$ Y ahora pondríamos:
$$P(el,perro,corre) = P(el|<s>)P(perro \,|\, el)P(corre \,|\, perro)P(</s>|corre)$$ 
Nótese que aún para frases más largas, sólo es necesario definir
$P(w|z)$ para cada para de palabras del vocabulario $w,z$, lo cual
es un simplificación considerable.

---

La probabilidad de bigramas también se puede escribir como, usando las convenciones de 
caracteres de inicio y de final de frase, como

$$P(w_1\cdots w_n) = \prod_{j=1}^n P(w_j | w_{j -1}).$$


Y así podemos seguir. Por ejemplo, con el **modelo de trigramas**,

$$P(w_1\cdots w_n) = P(w_3|w_1w_2)  P(w_4|w_2w_3) \cdots P(w_n| w_{n-2} w_{n-1}).$$

En este caso, usamos dos símbolos de inicio de frase $<s> <s>$ para que la fórmula tenga sentido.

**Observación**: los modelos de n-gramas son aproximaciones útiles, y fallan en la modelación de dependencias de larga distancia. Por ejemplo, en la frase "Tengo un gato en mi casa, y es de tipo persa" tendríamos que considerar n-gramas imprácticamente largos para modelar correctamente la ocurrencia de la palabra "persa" al final de la oración.


## Modelo de n-gramas usando conteos

Supongamos que tenemos una colección de textos o frases del lenguaje
que nos interesa.
¿Cómo podemos estimar las probabilidades del tipo $P(w|a)$ $P(w|a,b)$?

El enfoque más simple es estimación por máxima verosimilitud, que 
en esto caso implica estimar con conteos de ocurrencia
en el lenguaje. Si queremos
estimar $P(w|z)$ (modelo de bigramas), entonces tomamos nuestra colección, y calculamos:

- $N(z,w)$ = número de veces que aparece $z$ seguida de $w$
- $N(z)$ = número de veces que aparece $z$.
- $P(w|z) = \frac{N(z,w)}{N(z)}$

Nótese que estas probabilidades en general son chicas (pues el
vocabulario es grande), de forma que conviene usar las log probabilidades
para hacer los cálculos y evitar *underflows*. Calculamos entonces usando:

- $\log{P(w|z)} = \log{N(zw)} - \log{N(z)}$

¿Cómo se estimarían las probabilidades para el modelo de unigramas
y trigramas?

#### Ejercicio {-}
Considera la colección de textos "un día muy soleado", 
"un día muy lluvioso", "un ejemplo muy simple de bigramas". Estima
las probabilidades $P(muy|<s>)$, $P(día | un)$, $P(simple | muy)$ usando
conteos.

#### Ejemplo {-}

Comenzamos por limpiar nuestra colección de texto, creando también  *tokens* adicionales para signos de puntuación. En este caso solo tenemos dos textos:


```r
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

corpus_mini <- c("Este es un ejemplo: el perro corre, el gato escapa. Este es un número 3.1416, otro número es 1,23.", "Este   es otro ejemplo.  " )
normalizar(corpus_mini)
```

```
## [1] "este es un ejemplo _dos_puntos_ el perro corre _coma_ el gato escapa _punto_ este es un número 3 _punto_ 1416 _coma_ otro número es 1,23 _punto_ "
## [2] "este es otro ejemplo _punto_ "
```

Y ahora construimos, por ejemplo, los bigramas que ocurren en cada texto


```r
ejemplo <- tibble(txt = corpus_mini) |>
                mutate(id = row_number()) |>
                mutate(txt = normalizar(txt)) 
bigrams_ejemplo <- ejemplo |> 
                   unnest_tokens(bigramas, txt, token = "ngrams", 
                                 n = 2) |>
                   group_by(bigramas) |> tally()
knitr::kable(bigrams_ejemplo)
```



|bigramas             |  n|
|:--------------------|--:|
|_coma_ el            |  1|
|_coma_ otro          |  1|
|_dos_puntos_ el      |  1|
|_punto_ 1416         |  1|
|_punto_ este         |  1|
|1,23 _punto_         |  1|
|1416 _coma_          |  1|
|3 _punto_            |  1|
|corre _coma_         |  1|
|ejemplo _dos_puntos_ |  1|
|ejemplo _punto_      |  1|
|el gato              |  1|
|el perro             |  1|
|es 1,23              |  1|
|es otro              |  1|
|es un                |  2|
|escapa _punto_       |  1|
|este es              |  3|
|gato escapa          |  1|
|número 3             |  1|
|número es            |  1|
|otro ejemplo         |  1|
|otro número          |  1|
|perro corre          |  1|
|un ejemplo           |  1|
|un número            |  1|


## Notas de periódico: modelo de n-gramas simples.

En los siguientes ejemplos, utilizaremos una colección de
noticias cortas en español (de España).



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
length(periodico)
```

```
## [1] 309918
```

```r
periodico[1:2]
```

```
## [1] "En este sentido, señala que «no podemos consentir» que se repita «el malogrado caso del Centro de Transportes de Benavente, donde la falta de control ha supuesto un cúmulo de irregularidades que rozan lo delictivo»."                                                    
## [2] "\"Cuando acabe la experiencia con el Inter no me quedaré en Italia, sino que espero ir a España, porque mi objetivo es ganar los títulos de los tres campeonatos más competitivos del mundo\", afirmó el que fuera entrenador del Barcelona B, y añadió: \"me falta Liga\"."
```



```r
periodico_df <- tibble(txt = periodico) |>
                mutate(id = row_number()) |>
                mutate(txt = normalizar(txt)) 
```

Adicionalmente, seleccionamos una muestra para hacer las
demostraciones (puedes correrlo con todo el corpus):


```r
set.seed(123)
muestra_ind <- sample(1:nrow(periodico_df), 1e5)
periodico_m <- periodico_df[muestra_ind, ]
```

Y calculamos las frecuencias de todos unigramas, bigramas y trigramas:


```r
conteo_ngramas <- function(corpus, n = 1, vocab_df = NULL){
  token_nom <- paste0('w_n_', rev(seq(1:n)) - 1)
  token_cond <- token_nom[-length(token_nom)]
  # añadir inicio de frases
  inicio <- paste(rep("_s_ ", n - 1), collapse = "")
  # añadir fin de frases
  fin <- " _ss_"
  ngramas_df <- corpus |>
                mutate(txt = paste(inicio, txt, fin)) |>
                unnest_tokens(ngrama, txt, token = "ngrams", n = n) 
  frec_ngramas <- ngramas_df |> group_by(ngrama) |>
                  summarise(num = length(ngrama)) |>
                  separate(ngrama, token_nom, sep=" ") |>
                  group_by(across(all_of(token_cond))) |>
                  mutate(denom = sum(num)) |>
                  ungroup() |>
                  mutate(log_p = log(num) - log(denom))
  frec_ngramas
}
mod_uni <- conteo_ngramas(periodico_m, n = 1)
mod_bi  <- conteo_ngramas(periodico_m, n = 2)
mod_tri <- conteo_ngramas(periodico_m, n = 3)
```


```r
mod_uni |> arrange(desc(num)) |> head(100) |> knitr::kable()
```



|w_n_0        |    num|   denom|     log_p|
|:------------|------:|-------:|---------:|
|de           | 426481| 6894607| -2.782927|
|_coma_       | 380344| 6894607| -2.897419|
|la           | 261913| 6894607| -3.270482|
|_punto_      | 248139| 6894607| -3.324506|
|el           | 212825| 6894607| -3.478025|
|que          | 210647| 6894607| -3.488311|
|en           | 183614| 6894607| -3.625659|
|y            | 158689| 6894607| -3.771549|
|a            | 130347| 6894607| -3.968295|
|los          | 108758| 6894607| -4.149370|
|_ss_         | 100000| 6894607| -4.233325|
|del          |  84899| 6894607| -4.397032|
|se           |  77632| 6894607| -4.486515|
|las          |  68042| 6894607| -4.618370|
|un           |  66732| 6894607| -4.637810|
|por          |  62876| 6894607| -4.697330|
|con          |  60358| 6894607| -4.738201|
|una          |  49207| 6894607| -4.942459|
|para         |  48948| 6894607| -4.947736|
|no           |  46051| 6894607| -5.008745|
|su           |  42489| 6894607| -5.089250|
|ha           |  41228| 6894607| -5.119377|
|al           |  39885| 6894607| -5.152495|
|es           |  35381| 6894607| -5.272320|
|lo           |  27222| 6894607| -5.534469|
|más          |  27140| 6894607| -5.537486|
|como         |  26150| 6894607| -5.574646|
|este         |  16660| 6894607| -6.025484|
|pero         |  15365| 6894607| -6.106403|
|sus          |  14892| 6894607| -6.137671|
|han          |  14145| 6894607| -6.189134|
|o            |  13919| 6894607| -6.205240|
|esta         |  12189| 6894607| -6.337961|
|también      |  12089| 6894607| -6.346199|
|ya           |  12056| 6894607| -6.348932|
|dos          |  11364| 6894607| -6.408044|
|años         |  11314| 6894607| -6.412454|
|entre        |  11124| 6894607| -6.429390|
|le           |  11083| 6894607| -6.433082|
|_dos_puntos_ |  10785| 6894607| -6.460338|
|desde        |  10293| 6894607| -6.507031|
|sobre        |   9659| 6894607| -6.570605|
|año          |   9355| 6894607| -6.602584|
|si           |   9324| 6894607| -6.605903|
|fue          |   9224| 6894607| -6.616686|
|sin          |   8968| 6894607| -6.644832|
|está         |   8861| 6894607| -6.656835|
|hasta        |   8563| 6894607| -6.691044|
|todo         |   8409| 6894607| -6.709192|
|muy          |   8354| 6894607| -6.715754|
|cuando       |   8240| 6894607| -6.729494|
|según        |   8018| 6894607| -6.756806|
|son          |   7992| 6894607| -6.760054|
|porque       |   7548| 6894607| -6.817212|
|gobierno     |   7402| 6894607| -6.836745|
|euros        |   7310| 6894607| -6.849252|
|hay          |   7274| 6894607| -6.854188|
|ser          |   7198| 6894607| -6.864692|
|parte        |   6866| 6894607| -6.911913|
|tiene        |   6676| 6894607| -6.939976|
|_punto_coma_ |   6558| 6894607| -6.957809|
|así          |   6489| 6894607| -6.968386|
|todos        |   6424| 6894607| -6.978454|
|además       |   6403| 6894607| -6.981728|
|tras         |   6223| 6894607| -7.010243|
|aunque       |   6020| 6894607| -7.043407|
|tres         |   5965| 6894607| -7.052586|
|durante      |   5872| 6894607| -7.068300|
|sido         |   5845| 6894607| -7.072908|
|me           |   5823| 6894607| -7.076679|
|ayer         |   5774| 6894607| -7.085130|
|españa       |   5725| 6894607| -7.093652|
|000          |   5671| 6894607| -7.103129|
|uno          |   5532| 6894607| -7.127945|
|presidente   |   5488| 6894607| -7.135931|
|sólo         |   5388| 6894607| -7.154320|
|día          |   5372| 6894607| -7.157294|
|ahora        |   5353| 6894607| -7.160838|
|donde        |   5344| 6894607| -7.162520|
|pasado       |   5318| 6894607| -7.167397|
|después      |   5287| 6894607| -7.173244|
|hace         |   5206| 6894607| -7.188683|
|millones     |   5188| 6894607| -7.192146|
|partido      |   5036| 6894607| -7.221883|
|otros        |   4843| 6894607| -7.260960|
|vez          |   4787| 6894607| -7.272591|
|primera      |   4778| 6894607| -7.274473|
|ante         |   4682| 6894607| -7.294769|
|hoy          |   4663| 6894607| -7.298836|
|contra       |   4643| 6894607| -7.303134|
|había        |   4602| 6894607| -7.312004|
|puede        |   4590| 6894607| -7.314615|
|cada         |   4516| 6894607| -7.330868|
|equipo       |   4484| 6894607| -7.337979|
|personas     |   4479| 6894607| -7.339095|
|e            |   4464| 6894607| -7.342450|
|gran         |   4439| 6894607| -7.348066|
|ni           |   4418| 6894607| -7.352808|
|nos          |   4363| 6894607| -7.365335|
|antes        |   4352| 6894607| -7.367859|




```r
mod_bi |> arrange(desc(num)) |> head(100) |> knitr::kable()
```



|w_n_1    |w_n_0      |   num|  denom|      log_p|
|:--------|:----------|-----:|------:|----------:|
|_punto_  |_ss_       | 93073| 248139| -0.9806049|
|de       |la         | 64367| 426481| -1.8909667|
|en       |el         | 34475| 183614| -1.6726013|
|en       |la         | 29086| 183614| -1.8425788|
|de       |los        | 26980| 426481| -2.7604720|
|_coma_   |que        | 22964| 380344| -2.8071483|
|a        |la         | 22943| 130347| -1.7371872|
|que      |se         | 19073| 210647| -2.4019100|
|_coma_   |el         | 19019| 380344| -2.9956376|
|de       |las        | 16151| 426481| -3.2735859|
|_s_      |el         | 15308| 100000| -1.8767946|
|_coma_   |y          | 15277| 380344| -3.2147277|
|_coma_   |en         | 14330| 380344| -3.2787209|
|que      |el         | 13521| 210647| -2.7459397|
|_coma_   |la         | 13421| 380344| -3.3442555|
|_punto_  |el         | 12165| 248139| -3.0154261|
|a        |los        | 12116| 130347| -2.3756732|
|lo       |que        | 11115|  27222| -0.8957299|
|_s_      |la         | 10394| 100000| -2.2639415|
|que      |la         | 10203| 210647| -3.0275020|
|_coma_   |pero       |  9406| 380344| -3.6997283|
|con      |el         |  9033|  60358| -1.8994090|
|y        |el         |  9022| 158689| -2.8672803|
|_coma_   |con        |  8573| 380344| -3.7924584|
|por      |la         |  8400|  62876| -2.0129328|
|por      |el         |  8387|  62876| -2.0144816|
|_punto_  |la         |  8349| 248139| -3.3918473|
|en       |los        |  8314| 183614| -3.0948949|
|_punto_  |en         |  8114| 248139| -3.4203981|
|que      |no         |  8111| 210647| -3.2569626|
|con      |la         |  7989|  60358| -2.0222279|
|y        |la         |  7970| 158689| -2.9912618|
|de       |que        |  7956| 426481| -3.9816415|
|_coma_   |de         |  7696| 380344| -3.9003754|
|a        |las        |  7561| 130347| -2.8471967|
|_coma_   |se         |  7363| 380344| -3.9446086|
|_s_      |en         |  7271| 100000| -2.6212764|
|de       |un         |  7268| 426481| -4.0720867|
|_coma_   |a          |  7076| 380344| -3.9843673|
|en       |un         |  6681| 183614| -3.3135681|
|_coma_   |ha         |  6528| 380344| -4.0649755|
|en       |las        |  6237| 183614| -3.3823364|
|_coma_   |por        |  6218| 380344| -4.1136278|
|de       |su         |  6073| 426481| -4.2517151|
|se       |ha         |  6037|  77632| -2.5540725|
|y        |que        |  5964| 158689| -3.2812049|
|_punto_  |000        |  5671| 248139| -3.7786236|
|_coma_   |los        |  5604| 380344| -4.2175955|
|que      |los        |  5555| 210647| -3.6354853|
|de       |una        |  5551| 426481| -4.3415897|
|en       |su         |  5532| 183614| -3.5022863|
|la       |que        |  5432| 261913| -3.8757050|
|el       |que        |  5285| 212825| -3.6955976|
|_coma_   |como       |  5281| 380344| -4.2769606|
|que      |en         |  5084| 210647| -3.7240854|
|no       |se         |  4974|  46051| -2.2255251|
|que      |_coma_     |  4896| 210647| -3.7617652|
|_coma_   |según      |  4827| 380344| -4.3668509|
|y        |de         |  4796| 158689| -3.4991641|
|_punto_  |y          |  4447| 248139| -4.0217594|
|a        |su         |  4350| 130347| -3.4000243|
|_coma_   |no         |  4341| 380344| -4.4729714|
|que      |ha         |  4336| 210647| -3.8832315|
|en       |una        |  4263| 183614| -3.7628626|
|los      |que        |  4256| 108758| -3.2407955|
|para     |el         |  4160|  48948| -2.4652434|
|_coma_   |un         |  4072| 380344| -4.5369418|
|más      |de         |  4060|  27140| -1.8998257|
|con      |un         |  4056|  60358| -2.7000962|
|_coma_   |aunque     |  3931| 380344| -4.5721823|
|y        |en         |  3922| 158689| -3.7003446|
|_punto_  |los        |  3898| 248139| -4.1535255|
|millones |de         |  3866|   5188| -0.2941279|
|_s_      |los        |  3784| 100000| -3.2743885|
|para     |la         |  3766|  48948| -2.5647451|
|todos    |los        |  3617|   6424| -0.5743960|
|uno      |de         |  3593|   5532| -0.4315619|
|_punto_  |no         |  3562| 248139| -4.2436669|
|_punto_  |_punto_    |  3559| 248139| -4.2445095|
|para     |que        |  3535|  48948| -2.6280452|
|_coma_   |al         |  3524| 380344| -4.6814794|
|_coma_   |lo         |  3511| 380344| -4.6851752|
|_coma_   |ya         |  3499| 380344| -4.6885989|
|a        |un         |  3480| 130347| -3.6231678|
|ha       |sido       |  3430|  41228| -2.4865574|
|es       |el         |  3417|  35381| -2.3374120|
|ya       |que        |  3379|  12056| -1.2719827|
|y        |los        |  3363| 158689| -3.8541129|
|de       |este       |  3310| 426481| -4.8586196|
|es       |que        |  3303|  35381| -2.3713438|
|_coma_   |una        |  3255| 380344| -4.7608838|
|_coma_   |para       |  3229| 380344| -4.7689036|
|de       |sus        |  3219| 426481| -4.8864971|
|además   |_coma_     |  3192|   6403| -0.6961190|
|en       |este       |  3190| 183614| -4.0528148|
|el       |presidente |  3136| 212825| -4.2175221|
|con      |los        |  3134|  60358| -2.9579834|
|después  |de         |  3129|   5287| -0.5245375|
|y        |a          |  3092| 158689| -3.9381282|
|se       |han        |  3079|  77632| -3.2273748|

¿Qué palabra es más probable que aparezca después de *en*,
la palabra *la* o la palabra *el*?


```r
mod_tri |> arrange(desc(num)) |> head(100) |> knitr::kable()
```



|w_n_2      |w_n_1       |w_n_0   |   num|  denom|      log_p|
|:----------|:-----------|:-------|-----:|------:|----------:|
|_s_        |_s_         |el      | 15308| 100000| -1.8767946|
|_s_        |_s_         |la      | 10394| 100000| -2.2639415|
|_s_        |_s_         |en      |  7271| 100000| -2.6212764|
|_s_        |_s_         |los     |  3784| 100000| -3.2743885|
|_s_        |_s_         |por     |  2915| 100000| -3.5353004|
|en         |el          |que     |  2846|  34475| -2.4943199|
|_coma_     |en          |el      |  2724|  14330| -1.6602539|
|_coma_     |ya          |que     |  2619|   3499| -0.2896846|
|uno        |de          |los     |  2616|   3593| -0.3173411|
|_coma_     |lo          |que     |  2430|   3511| -0.3680096|
|en         |la          |que     |  2426|  29086| -2.4840131|
|millones   |de          |euros   |  2373|   3866| -0.4880654|
|_coma_     |en          |la      |  2283|  14330| -1.8368649|
|_coma_     |que         |se      |  2217|  22964| -2.3377728|
|_s_        |_s_         |las     |  1949| 100000| -3.9378538|
|_s_        |_s_         |a       |  1883| 100000| -3.9723039|
|sin        |embargo     |_coma_  |  1873|   2062| -0.0961350|
|por        |lo          |que     |  1862|   2350| -0.2327641|
|una        |de          |las     |  1759|   2423| -0.3202610|
|_coma_     |mientras    |que     |  1661|   2155| -0.2603709|
|_coma_     |por         |lo      |  1626|   6218| -1.3413253|
|a          |través      |de      |  1584|   1958| -0.2119703|
|_punto_    |000         |euros   |  1574|   5671| -1.2817453|
|_s_        |_s_         |no      |  1568| 100000| -4.1553693|
|_punto_    |además      |_coma_  |  1482|   1867| -0.2309403|
|_s_        |_s_         |según   |  1475| 100000| -4.2165122|
|_coma_     |así         |como    |  1404|   1721| -0.2035802|
|presidente |de          |la      |  1381|   2186| -0.4592655|
|a          |partir      |de      |  1361|   1738| -0.2445153|
|el         |presidente  |de      |  1331|   3136| -0.8570176|
|por        |su          |parte   |  1323|   2893| -0.7823921|
|_s_        |_s_         |de      |  1305| 100000| -4.3389671|
|que        |no          |se      |  1284|   8111| -1.8432410|
|_punto_    |en          |el      |  1271|   8114| -1.8537870|
|se         |trata       |de      |  1252|   1533| -0.2024843|
|_s_        |_s_         |además  |  1240| 100000| -4.3900588|
|su         |parte       |_coma_  |  1237|   1388| -0.1151748|
|a          |pesar       |de      |  1222|   1322| -0.0786569|
|_s_        |en          |el      |  1212|   7271| -1.7916219|
|_s_        |_s_         |para    |  1206| 100000| -4.4178611|
|_coma_     |y           |el      |  1204|  15277| -2.5406991|
|de         |la          |ciudad  |  1197|  64367| -3.9847827|
|de         |que         |el      |  1184|   7956| -1.9050278|
|_coma_     |a           |la      |  1119|   7076| -1.8442733|
|que        |se          |ha      |  1106|  19073| -2.8475238|
|en         |los         |últimos |  1104|   8314| -2.0190009|
|_coma_     |y           |que     |  1069|  15277| -2.6596248|
|_coma_     |con         |el      |  1068|   8573| -2.0828300|
|_coma_     |que         |ha      |  1032|  22964| -3.1024291|
|la         |que         |se      |  1032|   5432| -1.6608087|
|_s_        |_s_         |con     |  1016| 100000| -4.5892968|
|_coma_     |además      |de      |   986|   1822| -0.6140337|
|_s_        |en          |la      |   979|   7271| -2.0051175|
|el         |que         |se      |   962|   5285| -1.7036134|
|el         |caso        |de      |   961|   1655| -0.5435819|
|_coma_     |con         |un      |   950|   8573| -2.1999110|
|_s_        |_s_         |y       |   950| 100000| -4.6564635|
|_coma_     |pero        |no      |   948|   9406| -2.2947486|
|la         |guardia     |civil   |   938|   1027| -0.0906473|
|de         |lo          |que     |   936|   1979| -0.7487315|
|_punto_    |sin         |embargo |   933|   1216| -0.2649169|
|lo         |que         |se      |   923|  11115| -2.4884216|
|_s_        |además      |_coma_  |   919|   1240| -0.2995805|
|_coma_     |sobre       |todo    |   912|   1266| -0.3279776|
|en         |el          |caso    |   905|  34475| -3.6400548|
|que        |en          |el      |   902|   5084| -1.7292391|
|_s_        |_s_         |un      |   901| 100000| -4.7094202|
|_s_        |_s_         |pero    |   898| 100000| -4.7127554|
|no         |obstante    |_coma_  |   896|    948| -0.0564141|
|euros      |_punto_     |_ss_    |   881|   1632| -0.6165039|
|a          |la          |que     |   878|  22943| -3.2631216|
|_coma_     |que         |no      |   877|  22964| -3.2651761|
|_punto_    |en          |la      |   866|   8114| -2.2374613|
|_coma_     |con         |la      |   860|   8573| -2.2994406|
|el         |número      |de      |   856|   1229| -0.3616857|
|en         |este        |sentido |   854|   3190| -1.3178450|
|a          |lo          |largo   |   853|   1569| -0.6094342|
|_coma_     |de          |la      |   839|   7696| -2.2162453|
|_s_        |_s_         |así     |   836| 100000| -4.7842969|
|después    |de          |que     |   836|   3129| -1.3198401|
|de         |que         |la      |   828|   7956| -2.2626685|
|y          |de          |la      |   822|   4796| -1.7637971|
|castilla   |y           |león    |   817|    833| -0.0193945|
|_s_        |_s_         |una     |   812| 100000| -4.8134251|
|en         |los         |que     |   810|   8314| -2.3286619|
|_s_        |_s_         |tras    |   807| 100000| -4.8196018|
|la         |posibilidad |de      |   801|    858| -0.0687432|
|un         |total       |de      |   800|    823| -0.0283445|
|por        |parte       |de      |   797|   1139| -0.3570513|
|el         |presidente  |del     |   792|   3136| -1.3761420|
|_s_        |_s_         |al      |   788| 100000| -4.8434274|
|_s_        |_s_         |es      |   785| 100000| -4.8472417|
|_s_        |por         |su      |   781|   2915| -1.3170499|
|_coma_     |y           |la      |   775|  15277| -2.9812407|
|_punto_    |00          |horas   |   769|   1182| -0.4298722|
|y          |en          |el      |   767|   3922| -1.6318702|
|parte      |de          |la      |   762|   2513| -1.1932860|
|a          |los         |que     |   741|  12116| -2.7942815|
|_s_        |_s_         |también |   738| 100000| -4.9089816|
|el         |resto       |de      |   736|   1279| -0.5526037|

### Problema de los ceros {-}

Podemos ahora evaluar la probabilidad de ocurrencia de 
textos utilizando las frecuencias que calculamos arriba:


```r
n_gramas <- list(unigramas = mod_uni,
                 bigramas  = mod_bi,
                 trigramas = mod_tri)

log_prob <- function(textos, n_gramas, n = 2, laplace = FALSE, delta = 0.001, vocab_env = NULL){
  df <- tibble(id = 1:length(textos), txt = textos) |>
         mutate(txt = normalizar(txt)) 
  if(!is.null(vocab_env)){
    df <- df |> mutate(txt_u = map_chr(txt, ~restringir_vocab(.x, vocab = vocab_env))) |> 
    select(id, txt_u) |> rename(txt = txt_u)
  }
  token_nom <- paste0('w_n_', rev(seq(1:n)) - 1)
  df_tokens <- df |> group_by(id) |>
                unnest_tokens(ngrama, txt, 
                token = "ngrams", n = n) |>
                separate(ngrama, token_nom, " ") |>
                left_join(n_gramas[[n]], by = token_nom)
  if(laplace){
    V <- nrow(n_gramas[[1]])
    log_probs <- log(df_tokens[["num"]] + delta) - log(df_tokens[["denom"]] + delta*V )
    log_probs[is.na(log_probs)] <- log(1/V)
  } else {
    log_probs <- df_tokens[["log_p"]]
  }
  log_probs <- split(log_probs, df_tokens$id)
  sapply(log_probs, mean)
}
```


```r
textos <- c("un día muy soleado",
            "este de es ejemplo un",
            "este es un ejemplo de",
            "esta frase es exotiquísima")
log_prob(textos, n_gramas, n = 1)
```

```
##         1         2         3         4 
## -7.988631 -5.458781 -5.458781        NA
```

```r
log_prob(textos, n_gramas, n = 2)
```

```
##         1         2         3         4 
##        NA -7.824663 -3.722903        NA
```

```r
log_prob(textos, n_gramas, n = 3)
```

```
##         1         2         3         4 
##        NA        NA -2.177098        NA
```


**Observaciones**:

- El modelo de unigramas claramente no captura estructura en el orden de palabras. La segunda frase por ejemplo,
tiene probabilidad alta porque tiene tokens o palabras comunes, pero la frase en realidad tendría probabilidad muy
baja de ocurrir en el lenguaje. Esto parece incorrecto.
- La cuarta frase tiene probabilidad 0 en todos los modelos porque la palabra *exotiquísima* no existe en el vocabulario de entrenamiento. Esto parece incorrecto.
- La primera frase tiene probabilidad 0 en el modelo de bigramas y trigramas, porque nunca encontró alguna serie de tres palabras juntas. Esto parece incorrecto.

Incluso el modelo de bigramas puede dar probabilidad cero a frase que deberían ser relativamente comunes,
pues el conjunto de frases es muy grande:


```r
n <- 2
textos <- "Otro día muy soleado"
df <- tibble(id = 1:length(textos), txt = textos) |>
         mutate(txt = normalizar(txt))
token_nom <- paste0('w_n_', rev(seq(1:n)) - 1)
df_tokens <- df |> group_by(id) |>
                unnest_tokens(ngrama, txt, 
                token = "ngrams", n = n) |>
                separate(ngrama, token_nom, " ") |>
                left_join(n_gramas[[n]], by = token_nom)
df_tokens
```

```
## # A tibble: 3 × 6
## # Groups:   id [1]
##      id w_n_1 w_n_0     num denom log_p
##   <int> <chr> <chr>   <int> <int> <dbl>
## 1     1 otro  día        53  3995 -4.32
## 2     1 día   muy        15  5372 -5.88
## 3     1 muy   soleado    NA    NA NA
```

El problema es que no observamos "muy soleado", y esta frase tendría 0 probabilidad de ocurrir.

---

Esta última observación es importante: cuando no encontramos en nuestros conteos
un bigrama (o trigrama, etc.) dado, la probabilidad asignada es 0. 

Aunque para algunas frases esta asignación es correcta (una sucesión de palabras que casi no puede
ocurrir en el lenguaje), muchas veces esto se debe a que los datos son ralos: la mayor
parte de las frases posibles no son observadas en nuestro corpus, y es erróneo
asignarles probabilidad 0. Más en general, cuando los conteos de bigramas son
chicos, sabemos que nuestra estimación por máxima verosimilitud tendrá varianza 
alta.

Estos ceros ocurren de dos maneras:

- Algunas palabras son *nuevas*: no las observamos en nuestros
datos de entrenamiento.
- No observamos bigramas, trigramas, etc. específicos (por ejemplo,
observamos *día*, y *aburrido* pero no observamos *día aburrido*).

#### Palabras desconocidas {-}

Para el primer problema, podemos entrenar nuestro modelo
con una palabra adicional $<unk>$, que denota palabras desconocidas. Una
estrategia es tomar las palabras con frecuencia baja y sustituirlas por
<unk>, por ejemplo:


```r
vocabulario_txt <- n_gramas[[1]] |> filter(num > 1) |> 
    pull(w_n_0)
vocab_env <- new.env()
vocab_env[["_unk_"]] <- 1
for(a in vocabulario_txt){
    vocab_env[[a]] <- 1
}
nrow(n_gramas[[1]])
```

```
## [1] 137263
```

```r
sum(n_gramas[[1]]$num)
```

```
## [1] 6894607
```

```r
length(vocab_env)
```

```
## [1] 77933
```


```r
restringir_vocab <- function(texto, vocab_env){
  texto_v <- strsplit(texto, " ")[[1]]
  texto_v <- lapply(texto_v, function(x){
    if(x != ""){
        en_vocab <- vocab_env[[x]]
        if(is.null(en_vocab)){
            x <- "_unk_"
        }
        x
    }
  })
  texto <- paste(texto_v, collapse = " ")
  texto
}
periodico_m_unk <- periodico_m |> 
    mutate(txt_u = map_chr(txt, ~restringir_vocab(.x, vocab_env = vocab_env))) |> 
    select(id, txt_u) |> rename(txt = txt_u)
```


Y ahora podemos reentrenar nuestros modelos:


```r
mod_uni <- conteo_ngramas(periodico_m_unk, n = 1)
mod_bi  <- conteo_ngramas(periodico_m_unk, n = 2)
mod_tri <- conteo_ngramas(periodico_m_unk, n = 3)
n_gramas_u <- list(mod_uni, mod_bi, mod_tri)
```


```r
textos <- c("un día muy soleado",
            "este de es ejemplo un",
            "este es un ejemplo de",
            "esta frase es exotiquísima")
log_prob(textos, n_gramas_u, n = 1, vocab_env = vocab_env)
```

```
##         1         2         3         4 
## -8.005118 -5.470732 -5.470732 -6.447402
```

```r
log_prob(textos, n_gramas_u, n = 2, vocab_env = vocab_env)
```

```
##         1         2         3         4 
##        NA -7.887497 -3.756993 -4.468375
```

```r
log_prob(textos, n_gramas_u, n = 3, vocab_env = vocab_env)
```

```
##         1         2         3         4 
##        NA        NA -2.232099        NA
```

Y con esto podemos resolver el problema de vocabulario desconocido.

#### Contexto no observado {-}

Para el segundo problema, existen **técnicas de suavizamiento** (que veremos más adelante). El método más simple es el **suavizamiento de Laplace**,
en el que simplemente agregamos una cantidad $\delta$ a los conteos de unigramas, bigramas, etc.

Para unigramas, agregamos $\delta$ a cada posible unigrama. Si el tamaño del vocabulario
es $V$, y el conteo total de *tokens* es $N$, el nuevo conteo de *tokens* será entonces
$N+\delta V$.  Por ejemplo, la probabilidad para bigramas es:

$$P(w|a) = \frac{N(aw)}{N(a)} = \frac{N(aw)}{\sum_{z\in V} N(az)},$$
De modo que la estimación suavizada (sumando $\delta$ a cada bigrama) es
$$P_{L}(w|a) = \frac{N(aw)+\delta}{\sum_{z\in V} N(az)+\delta}= \frac{N(aw) + \delta}{N(z)+ \delta V} $$
Para trigramas,
$$P_{L}(w|ab) = \frac{N(abw)+\delta}{\sum_{z\in V} N(abz)+\delta}= \frac{N(abw) + \delta}{N(ab)+ \delta V} $$
y así sucesivamente.

**Observación**: este método es útil para introducir la idea de
suavizamiento, pero existen otros mejores que veremos más adelante
(ver sección 4.5 de [@jurafsky], o 3.5 en la edición más reciente). Veremos más adelante también cómo
escoger hiperparámetros como $\delta$.


```r
log_prob(textos, n_gramas_u, n = 1, laplace = TRUE, delta = 0.01)
```

```
##         1         2         3         4 
## -8.004979 -5.470842 -5.470842 -8.337738
```

```r
log_prob(textos, n_gramas_u, n = 2, laplace = TRUE, delta = 0.01)
```

```
##         1         2         3         4 
## -7.337730 -8.021005 -3.894912 -7.558278
```

```r
log_prob(textos, n_gramas_u, n = 3, laplace = TRUE, delta = 0.01)
```

```
##          1          2          3          4 
##  -7.907155 -11.252417  -3.477082 -11.252417
```

Nótese que este suavizamiento cambia considerablemente las probabilides estimadas,
incluyendo algunas de ellas con conteos altos (esta técnica dispersa demasiada
probabilidad sobre conteos bajos).


## Evaluación de modelos

### Generación de texto

Una primera idea de qué tan bien funcionan estos modelos es generando
frases según las probabilidades que estimamos.

#### Ejemplo: unigramas {-}

Generamos algunas frases bajo el modelo de unigramas. Podemos construir
una frase comenzando con el token $<s>$, y paramos cuando encontramos
$</s>$. Cada token se escoge al azar según las probablidades $P(w)$.


```r
calc_siguiente_uni <- function(texto, n_gramas){
  u <- runif(1)
  unigramas_s <- arrange(n_gramas[[1]], log_p) 
  prob_acum <- cumsum(exp(unigramas_s$log_p))
  palabra_no <- match(TRUE, u < prob_acum)
  as.character(unigramas_s[palabra_no, "w_n_0"])
}
texto <- ""
fin <- FALSE
set.seed(1215)
while(!fin){
  siguiente <- calc_siguiente_uni(texto, n_gramas)
  texto <- c(texto, siguiente)
  if(siguiente == "_ss_"){
    fin <- TRUE
  }
}
paste(texto, collapse = " ")
```

```
## [1] " las que baleares del con del agua en señalándoles si de en ha mismas _punto_ se pp el de _coma_ los del que _punto_ la en reiterado _punto_ cuentan y los _coma_ derechos hoy la _coma_ al talento en buena gobierno sólo de genero aguas uvi a arreos un en en 3 dos de que es del porque que _ss_"
```


#### Ejemplo: bigramas


```r
calc_siguiente_bi <- function(texto, n_gramas){
  u <- runif(1)
  n <- length(texto)
  anterior <- texto[n]
  siguiente_df <- filter(n_gramas[[2]], w_n_1 == anterior) |> 
    arrange(log_p) 
  palabra_no <- match(TRUE, u < cumsum(exp(siguiente_df$log_p)))
  as.character(siguiente_df[palabra_no, "w_n_0"])
}
texto <- "_s_"
set.seed(4123)
fin <- FALSE
while(!fin){
  siguiente <- calc_siguiente_bi(texto, n_gramas)
  texto <- c(texto, siguiente)
  if(siguiente == "_ss_"){
    fin <- TRUE
  }
}
paste(texto, collapse = " ")
```

```
## [1] "_s_ el concierto pueden encontrarse las poblaciones como la mano derecha de la delincuencia y la mañana en la trama de las alarmas en valladolid _coma_ o alemania podría haber aprendido del documento especifique los portavoces que en el 78 de mehr solar construirá tres fronteras y lo que garantiza la fundación personas indicadas todas las encuestadas 11 españoles _punto_ danays llegaba la posibilidad de la lleva puesto sus aliados parlamentarios para otro tipo de la ola que una hermana con su aventura _punto_ un feto de españa en el sip entre operadores turísticos cuya desembocadura _punto_ definitivamente del ipc previsto entregar al final _coma_ la realidad _punto_ el proceso de interposición de algeciras _coma_ el acuerdo con su educación _coma_ porque prevalecen y no han concluido y llegar al trabajo bien _punto_ _ss_"
```


#### Ejemplo: trigramas


```r
calc_siguiente_tri <- function(texto, n_gramas){
  u <- runif(1)
  n <- length(texto)
  contexto <- texto[c(n,n-1)]
  siguiente_df <- filter(n_gramas[[3]], w_n_1 == contexto[1], w_n_2 == contexto[2]) |> 
    arrange(log_p)
  palabra_no <- match(TRUE, u < cumsum(exp(siguiente_df$log_p)))
  as.character(siguiente_df[palabra_no, "w_n_0"])
}
texto <- c("_s_","_s_")
set.seed(4122)
fin <- FALSE
while(!fin){
  siguiente <- calc_siguiente_tri(texto, n_gramas)
  texto <- c(texto, siguiente)
  if(siguiente == "_ss_"){
    fin <- TRUE
  }
}
paste(texto, collapse = " ")
```

```
## [1] "_s_ _s_ en relación con su marido figura entre los años a la formación de salida _coma_ despistado por el gran número de asuntos exteriores y economía y hacienda de los siglos xvi y xvii relacionados con la que se descarta y en el paseo de la escuela de comunicación _coma_ o su boda en normandía _punto_ al mismo tiempo _coma_ esquivar el golpe le desplazó casi 60 millones de euros para emprender estas obras supusieron la eliminación de barreras arquitectónicas _punto_ _ss_"
```

**Observación**: en este ejemplo vemos cómo los textos parecen más textos reales
cuando usamos n-gramas más largos. 

### Evaluación de modelos: perplejidad

 En general,
la mejor manera de hacer la evaluación de un modelo de lenguaje es en el contexto
de su aplicación (es decir, el desempeño en la tarea final para el que construimos
nuestro modelo): por ejemplo, si se trata de corrección de ortografía, qué tanto da la palabra
correcta, o qué tanto seleccionan usuarios palabras del corrector.

Sin embargo también podemos hacer una evaluación intrínseca del modelo considerando
muestras de entrenamiento y prueba. Una medida usual en este contexto
es la **perplejidad**.

\BeginKnitrBlock{resumen}<div class="resumen">Sea $P(W)$ un modelo del lenguaje. Supongamos que observamos
un texto $W=w_1 w_2\cdots w_N$ (una cadena larga, que puede incluír varios separadores
$</s>, <s>$). La **log-perplejidad** del modelo sobre este texto es igual a
$$LP(W) = -\frac{1}{N} \log P(w_1 w_2 \cdots w_N),$$
  que también puede escribirse como
$$LP(W) = -\frac{1}{N} \sum_{i=1}^N \log P(w_i|w_1 w_2 \cdots w_{i-1})$$
La perplejidad es igual a
$$PP(W) = e^{LP(W)},$$ 
que es la medida más frecuentemente reportada en modelos de lenguaje.</div>\EndKnitrBlock{resumen}

**Observaciones**: 

- La log perplejidad es similar a la devianza (negativo de log-verosimilitud)
de los datos (palabras) observadas $W$ bajo el modelo $P$.
- Cuanto más grande es $P(W)$ bajo el modelo, menor es la perplejidad.
- Mejores modelos tienen valores más bajos de perplejidad. Buscamos
modelos que asignen muy baja probabilidad a frases que no son 
gramáticas, o no tienen sentido, y alta probabilidad a frases
que ocurren con frecuencia.

Bajo el modelo de bigramas, por ejemplo, tenemos que

$$LP(W) = -\frac{1}{N} \sum_{i=1}^N \log P(w_i|w_{i-1})$$

Y para el modelo de trigramas:
$$LP(W) = -\frac{1}{N} \sum_{i=1}^N \log P(w_i|w_{i-2}w_{i-1})$$

\BeginKnitrBlock{resumen}<div class="resumen">- La evaluación de modelos la hacemos calculando la perplejidad en una
muestra de textos de prueba, que no fueron utilizados para
entrenar los modelos.
- Para palabras no vistas, entrenamos nuestros modelos sustituyendo
palabras no frecuentes con $<unk>$, y a las palabras no vistas
les asignamos el token $<unk>$.</div>\EndKnitrBlock{resumen}

---

#### Ejemplo {-}

Podemos usar nuestra función anterior para calcular la perplejidad. Para
los datos de entrenamiento vemos que la perplejidad de entrenamiento es mejor para
los modelos más complejos:


```r
periodico_entrena <- periodico[muestra_ind]
textos <- periodico_entrena[1:1000]
texto_entrena <- paste(textos, collapse = " ")
exp(-log_prob(texto_entrena, n_gramas_u, n = 1, laplace = T))
```

```
##        1 
## 1054.776
```

```r
exp(-log_prob(texto_entrena, n_gramas_u, n = 2, laplace = T))
```

```
##        1 
## 174.3516
```

```r
exp(-log_prob(texto_entrena, n_gramas_u, n = 3, laplace = T))
```

```
##        1 
## 105.3819
```

Pero para la muestra de prueba:




```r
periodico_prueba <- periodico[-muestra_ind]
textos <- periodico_prueba[1:1000]
texto_prueba <- paste(textos, collapse = " ")
exp(-log_prob(texto_prueba, n_gramas_u, n = 1, laplace = T))
```

```
##        1 
## 1006.145
```

```r
exp(-log_prob(texto_prueba, n_gramas_u, n = 2, laplace = T))
```

```
##        1 
## 320.2612
```

```r
exp(-log_prob(texto_prueba, n_gramas_u, n = 3, laplace = T))
```

```
##        1 
## 1554.325
```

Y vemos para este ejemplo que el mejor desempeño está dado por el modelo de bigramas, aunque no hemos hecho ningún ajuste ad-hoc del parámetro $\delta$. Como explicamos arriba,
es preferible usar otros algoritmos de suavizamiento.


####  Ejercicio {-}
Discute por qué: 

- El modelo de bigramas se desempeña mejor que el de unigramas
en la muestra de prueba.
- Parece que el modelo de trigramas, con 
nuestra colección de textos chicos, parece "sobreajustar", y tener
mal desempeño sobre la muestra de prueba. 


## Suavizamiento de conteos: otros métodos

Como discutimos arriba, el primer problema para generalizar
a frases o textos que no hemos visto, es que muchas veces no
observamos en nuestros datos de entrenamiento 
ciertos n-gramas con probabiliidad relativamente alta. Arriba
propusimos el suavizamiento de Laplace, que es una manera
burda de evitar los ceros y se basa en la idea de quitar
un poco de probabilidad a los n-gramas observados y redistribuir
sobre los no observados.

Podemos considerar métodos mejores observando que cuando
el contexto es muy grande (por ejemplo, trigramas), es fácil
no encontrar 0's en frases usuales del lenguaje (por ejemplo,
encontramos "Una geometría euclideana", "Una geometría no-euclideana",
pero nunca observamos Una geometría hiperbólica"). En este
caso, podríamos bajar a usar los *bigramas*, y considerar solamente
el bigrama "geometría hiperbólica", que quizá tiene algunas
ocurrencias en la muestra de entrenamiento. A este proceso se 
le llama **backoff**.

Un método popular con mejor desempeño que Laplace es
el método de descuento absoluto (da) de **Kneser-Ney**. Consideremos el caso de bigramas.

En primer lugar, este método utiliza interpolación entre bigramas y unigramas, 
considerando que debemos quitar algo de masa de probabilidad 
a bigramas observados para distribuir en bigramas no observados. El descuento lo
hacemos absoluto (por ejemplo restando $d=0.75$, ver [@jurafsky])

$$P_{da}(w|a) = \frac{N(aw) - d}{N(a)} + \lambda(a) P(w).$$

Así que reducimos los conteos observados por una fracción
$d$, e interpolamos con las probabilidad de ocurrencia de unigramas. $\lambda(a)$ es tal que la suma de todas las probabilidades es igual a 1: $\sum_w P(w|a) = 1$. El lado derecho de esta ecuación toma valores positivos
siempre y cuando $N(w)\geq 1$, que suponemos (vocabulario completo, quizá incluyendo unk).

Esta primera parte de descuento absoluto pone masa de probabilidad sobre bigramas no vistos. Podemos
mejorar si en lugar de considerar $P(w)$ consideramos una cantidad más específica, como sigue:

En vez de usar las probabilidades crudas
de unigramas $P(w)$, usamos las probabilidades de continuación
de unigramas $P_{cont}(w)$, pues aquí $w$ aparece como continuación después de $a$:

$$P_{cont}(w) = \frac{\sum_{z\in V} I(N(zw) >0) }
{ \sum_{z, b\in V} I(N(zb > 0))}.$$

Que simplemente es la probabilidad de que $w$ sea una continuación después de alguna palabra (en el denominador están todas las posibles continuaciones sobre todas las palabras). Verifica que $\sum_{w\in V} P_{cont} (w) = 1$, de forma que es una distribución de probabilidad
sobre los unigramas.

La idea de este método se basa en la siguiente observación: 

- Hay palabras como *embargo* que principalmente ocurren como continuación
de palabras específicas (**sin embargo**). En general, su probabilidad de continuación es baja. 
- Pero *embargo* puede tener probabilidad de unigrama alto porque *sin embargo* ocurre frecuentemente.
- En una frase como "Este es un día ...", quizá *aburrido* ocurre menos que *embargo*, pero *aburrido* es una continuación más apropiada, pues ocurre más como continuación de otras palabras.
- Si usamos las probabilidad de continuación, veríamos que 
$P_{cont}(embargo)$ es baja, pero $P_{cont}(aburrido)$ es más alta,
pues *aburrido* ocurre más como continuación.

Usaríamos entonces:

$$P_{da}(w|a) = \frac{N(aw) - d}{N(a)} + \lambda(a) P_{cont}(w).$$


### Desempeño {-}

Cuando construimos modelos grandes, una búsqueda directa en
una base de datos usual de n-gramas puede ser lenta (por ejemplo,
considera cómo funcionaría el *auto-complete* o la corrección de ortografía).

Hay varias alternativas. Se pueden filtrar los n-gramas menos frecuentes (usando las ideas de arriba para hacer backoff o interpolación con unigramas), y utilizar estructuras
apropiadas para encontrar los n-gramas. Otra solución es utilizar algoritmos más simples como
**stupid backoff** (que se usa para colecciones muy grandes de texto),
que consiste en usar la probabilidad del (n-1)-grama multiplicado
por una constante fija $\lambda$ si no encontramos el n-grama
que buscamos (Ver [@jurafsky]).

Finalmente, una opción es utilizar **filtros de bloom** para
obtener aproximaciones de los conteos. Si la frecuencia
de un n-grama $w$ es $f$, por ejemplo, insertamos en 
el filtro el elemento $(w, 2^j)$ para toda $j$ tal que
$2^j < f$. Para estimar un conteo de un n-grama observado,
simplemente checamos sucesivamente si el elemento $(w, 2^j)$ está
en el filtro o no, hasta que encontramos una $k$ tal que
$(w, 2^{k+1})$ no está en el filtro. Nuestra estimación
de la frecuencia del n-grama $w$ es entonces $2^k \leq f < 2^{k+1}$


## Ejemplo: Corrector de ortografía

Como ejemplo del canal ruidoso y el papel que juega los modelos del lenguaje, podemos
ver un sistema simple de corrección de ortografía.

En nuestro caso, usaremos como $P(W)$ el modelo de bigramas, y el modelo de ruido
$P(X|W)$ es simple: lo construimos a partir de palabras $p(x|w)$, y consideramos que dada
una palabra $w$, es posible observar $x$, donde $w$ se produce como transformación de $x$ aplicando:

1. Una eliminación de un caracter
2. Inserción de un caracter
2. Sustitución de un caracter
3. Transposición de dos caracteres adyacentes

Daremos igual probabilidad a todas estas posiblidades, aunque en la realidad este modelo
debería ser más refinado (¿cómo mejorarías este modelo?¿Con qué datos?).

En el siguiente paso tendríamos que producir sugerencias de corrección.
En caso de encontrar una palabra que no está en el diccionario,
podemos producir palabras similares (a cierta distancia de edición),
y filtrar aquellas que están en el vocabulario (ver [How to write a spelling corrector](http://norvig.com/spell-correct.html)).




```r
generar_candidatos <- function(palabra){
  caracteres <- c(letters, 'á', 'é', 'í', 'ó', 'ú', 'ñ')
  pares <- lapply(0:(nchar(palabra)), function(i){
    c(str_sub(palabra, 1, i), str_sub(palabra, i+1, nchar(palabra)))
  })
  eliminaciones <- pares |> map(function(x){ paste0(x[1], str_sub(x[2],2,-1))})
  sustituciones <- pares |> map(function(x)
      map(caracteres, function(car){
    paste0(x[1], car, str_sub(x[2], 2 ,-1))
  })) |> flatten() 
  inserciones <- pares |> map(function(x){
    map(caracteres, function(car) paste0(x[1], car, x[2]))
  }) |> flatten()
  transposiciones <- pares |> map(function(x){
    paste0(x[1], str_sub(x[2],2,2), str_sub(x[2],1,1), str_sub(x[2],3,-1))
  })
  c(eliminaciones, sustituciones, transposiciones, inserciones)
}
```


```r
candidatos <- generar_candidatos("solado")
sprintf("Número de candidatos generados: %0.i", length(candidatos))
```

```
## [1] "Número de candidatos generados: 462"
```

```r
print("Algunos candidatos:")
```

```
## [1] "Algunos candidatos:"
```

```r
head(candidatos)
```

```
## [[1]]
## [1] "olado"
## 
## [[2]]
## [1] "slado"
## 
## [[3]]
## [1] "soado"
## 
## [[4]]
## [1] "soldo"
## 
## [[5]]
## [1] "solao"
## 
## [[6]]
## [1] "solad"
```


```r
sugerir <- function(frase, mod_bi){
  tokens <- normalizar(frase) |> str_split(" ") |> first() |> tail(2)
  candidatos <- generar_candidatos(tokens[2])
  candidatos_tbl <- mod_bi |> filter(w_n_1 == tokens[1], w_n_0 %in% c(tokens[2], candidatos)) |> 
    mutate(log_posterior = 0 + log_p) # suponemos todos las corrupciones igualmente probabiles
  arrange(candidatos_tbl, desc(log_posterior))
}
```


```r
sugerir(c("esto es un echo"), mod_bi) |> head()
```

```
## # A tibble: 5 × 6
##   w_n_1 w_n_0   num denom  log_p log_posterior
##   <chr> <chr> <int> <int>  <dbl>         <dbl>
## 1 un    hecho   115 66008  -6.35         -6.35
## 2 un    techo    20 66008  -8.10         -8.10
## 3 un    eco       4 66008  -9.71         -9.71
## 4 un    ocho      4 66008  -9.71         -9.71
## 5 un    pecho     1 66008 -11.1         -11.1
```


```r
sugerir("dice que lo hechó", mod_bi)
```

```
## # A tibble: 2 × 6
##   w_n_1 w_n_0   num denom log_p log_posterior
##   <chr> <chr> <int> <int> <dbl>         <dbl>
## 1 lo    hecho    13 26883 -7.63         -7.63
## 2 lo    echó      5 26883 -8.59         -8.59
```


```r
sugerir("un pantalón asul", mod_bi)
```

```
## # A tibble: 1 × 6
##   w_n_1    w_n_0   num denom log_p log_posterior
##   <chr>    <chr> <int> <int> <dbl>         <dbl>
## 1 pantalón azul      2    48 -3.18         -3.18
```

Este modelo está basado en bigramas, pero podemos usar también unigramas por ejemplo para
producir recomendaciones cuando no encontremos bigramas apropiados.


