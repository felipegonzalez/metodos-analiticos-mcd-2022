# Pagerank y análisis de redes

## Introducción

**Pagerank** asigna un número real a cada página de una red (web). Este número es un indicador de su importancia. Las ideas fundamentales son: 

- Las páginas de internet forman una red o gráfica, donde los nodos son las páginas y las aristas dirigidas son las ligas de unas páginas a otras.
- La importancia de un página A depende de cuántas otras páginas apuntan a la página A. También depende de qué tan importantes sean las páginas que apuntan a A.
- Cuando hacemos una búsqueda, primero se filtran las páginas que tienen el contenido
de nuestra búsqueda, y después los resultados se ordenan según el pagerank
de estas páginas filtradas.
- ¿Qué problema resuelve? En un principio, se usaron métodos como índices y recuperación de documentos usando técnicas como tf-idf. El problema es que es muy fácil que un *spammer* sesgue los resultados para que sus páginas tengan alto nivel de relevancia en este sentido. Así que la importancia no se juzga sólo con el contenido,  sino de los *votos* de otras páginas importantes. Este es un sistema más difícil de engañar.

- Es crucial usar la importancia de los *in-links* de una página; si no, sería tambíen fácil crear muchas páginas spam que apunten a otra dada para aumentar
su importancia.

El *Pagerank*, más en general, es una medida de *centralidad* o *importancia* de los nodos de una red dirigida. Comenzaremos considerando redes más variadas (por ejemplo, redes sociales) y el concepto general de *centralidad*.

### Centralidad en redes 

Consideremos una red de personas, que representamos como una gráfica $G$ no dirigida o dirigida, dependiendo del caso. Las personas son los nodos y sus relaciones se representan con aristas.

Quiséramos construir una medida de importancia o centralidad de una persona dentro de la red. Por ejemplo:

- Redes sociales de internet: las ligas representan relación de *amigos*,
o la de *seguidor*.  Importancia: número de amigos o seguidores (grado de entrada o salida).
- Redes de citas bibliográficas: las ligas representan quién comparte o usa la información de quién. Importancia: número de citas o usos, ser citado por alguien importante, etc. 
- Red de empleados de una oficina: las ligas representan interacciones en algún periodo. Importancia: quién puede conectar de manera más inmediata a dos personas.


### Ejemplo de Moviegalaxies.com: Pulp Fiction {-}

 Dos personajes están ligados si tienen interacciones en la película. El tamaño y color de los nodos dependen de su "centralidad" en la red.

![Pulp fiction](./images/pulpfiction.png)

(Gráfica creada con *Gephi*).

## Tipos de redes y su representación

Una red es un conjunto de *nodos* conectados por algunas *aristas*. 
Las aristas pueden ser 

- Dirigidas: hay un nodo origen y un nodo destino.
- No dirigidas: una arista representa una conexión simétrica entre dos nodos.

Podemos representar redes de varias maneras. Una primera manera
es con una lista de pares de *vértices* o *nodos* 
que están conectados por una *arista*. Por ejemplo, para una red dirigida:


```r
library(tidyverse)
library(tidygraph)
library(ggraph)
aristas <- tibble(from = c(1, 1, 1, 1, 2), 
                      to =   c(2, 3, 4, 5, 3))
aristas
```

```
## # A tibble: 5 × 2
##    from    to
##   <dbl> <dbl>
## 1     1     2
## 2     1     3
## 3     1     4
## 4     1     5
## 5     2     3
```


```r
red_tbl <- tidygraph::as_tbl_graph(aristas, directed = TRUE)
red_tbl
```

```
## # A tbl_graph: 5 nodes and 5 edges
## #
## # A directed acyclic simple graph with 1 component
## #
## # Node Data: 5 × 1 (active)
##   name 
##   <chr>
## 1 1    
## 2 2    
## 3 3    
## 4 4    
## 5 5    
## #
## # Edge Data: 5 × 2
##    from    to
##   <int> <int>
## 1     1     2
## 2     1     3
## 3     1     4
## # … with 2 more rows
```

Que podemos visualizar como sigue:


```r
graficar_red_dirigida <- function(red_tbl){
  ggraph(red_tbl) + 
    geom_edge_link(arrow = arrow(), end_cap = circle(4, 'mm')) +
    geom_node_point(size = 10, colour = 'salmon') +
    geom_node_text(aes(label = name)) +
    theme_graph() + coord_fixed()
}
graficar_red_dirigida(red_tbl)
```

```
## Using `sugiyama` as default layout
```

<img src="06-pagerank_files/figure-html/unnamed-chunk-3-1.png" width="576" />

También es posible representar una red mediante una **matriz de adyacencia**. 

La matriz de adyacencia para una red es la matriz $A$ tal que
$$A_{ij} = 1$$
si existe una arista de $i$ a $j$. En el caso no dirigido, $A$ es una
matriz simétrica.


```r
matriz_ad <- igraph::get.adjacency(red_tbl)
matriz_ad
```

```
## 5 x 5 sparse Matrix of class "dgCMatrix"
##   1 2 3 4 5
## 1 . 1 1 1 1
## 2 . . 1 . .
## 3 . . . . .
## 4 . . . . .
## 5 . . . . .
```

Es más conveniente representar estas matrices como matrices ralas,
como veremos más adelante.

**Nota de R**: utilizamos el paquete *tidygraph* y **ggraph** para hacer manipulaciones de gráficas y graficación. Estos paquetes son extensiones
del paquete  *igraph*, que es el que contiene los algoritmos de visualización, procesamiento
y resumen de redes.


## Visualización de redes

Existen varios algoritmos para visualizar redes que revelan distintos aspectos de su estructura (ver por ejemplo *?layout* en R, en el paquete *igraph*). 

Por ejemplo, aquí construimos una red aleatoria, y hacemos un *layout* de
nodos aleatorio:


```r
set.seed(1234)
g <- play_erdos_renyi(n = 20, p = 0.1, directed = FALSE) |> as_tbl_graph()
ggraph(g, layout = 'randomly') + geom_edge_link() +
  geom_node_point(size = 2, colour = 'salmon') +
  theme_graph()
```

<img src="06-pagerank_files/figure-html/unnamed-chunk-5-1.png" width="576" />

Y comparamos con la representación producida por un algoritmo basado en fuerzas.


```r
ggraph(g, layout = 'fr') + geom_edge_link() +
    geom_node_point(size = 2, colour = 'salmon') +
    theme_graph()
```

<img src="06-pagerank_files/figure-html/unnamed-chunk-6-1.png" width="576" />

\BeginKnitrBlock{resumen}<div class="resumen">Los algoritmos basados en fuerzas para representar redes en $2$ o $3$ dimensiones se basan principalmente en la siguiente idea:

- Las aristas actúan como resortes, que no permiten que nodos ligados se alejen mucho
- Los nodos tienen fuerzas de repulsión entre ellos (la analogía física es de cargas elécricas), y también a veces de gravedad entre ellos.
- El algoritmo de representación intenta minimizar la energía de la configuración del sistema de atracciones y repulsiones.</div>\EndKnitrBlock{resumen}

Hay muchas variaciones de estos algoritmos, por ejemplo: *graphopt* en *igraph*, 
*fruchtermann-rheingold*, *kamada-kawai*, *gem*, *escalamiento multidimensional*, *forceAtlas*,
etc. Intenta mover los nodos de las siguiente gráfica para entender el funcionamiento
básico de estos algoritmos:


```r
library(visNetwork)
edges <- g |> activate(edges) |> as_tibble()
set.seed(13)
red_vis <- visNetwork(nodes = tibble(id = 1:20, label = 1:20), 
           edges, width = "100%") |>
  visPhysics(solver ='forceAtlas2Based', 
             forceAtlas2Based = list(gravitationalConstant = - 50, # negativo!
                              centralGravity = 0.01, 
                              springLength = 100,
                              springConstant = 0.08,
                              avoidOverlap = 0
                              ))
red_vis
```

```{=html}
<div id="htmlwidget-d702bf6449cc05af9583" style="width:100%;height:480px;" class="visNetwork html-widget"></div>
<script type="application/json" data-for="htmlwidget-d702bf6449cc05af9583">{"x":{"nodes":{"id":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20],"label":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]},"edges":{"from":[4,5,8,1,1,8,10,6,8,11,6,11,9,16,2,4,5,11,16,13,17,18],"to":[8,8,10,12,13,13,14,15,15,15,16,17,18,18,19,19,19,19,19,20,20,20]},"nodesToDataframe":true,"edgesToDataframe":true,"options":{"width":"100%","height":"100%","nodes":{"shape":"dot"},"manipulation":{"enabled":false},"physics":{"solver":"forceAtlas2Based","forceAtlas2Based":{"gravitationalConstant":-50,"centralGravity":0.01,"springLength":100,"springConstant":0.08,"avoidOverlap":0}}},"groups":null,"width":"100%","height":null,"idselection":{"enabled":false},"byselection":{"enabled":false},"main":null,"submain":null,"footer":null,"background":"rgba(0, 0, 0, 0)"},"evals":[],"jsHooks":[]}</script>
```


### Ejercicio
- Para la gráfica anterior, busca qué parámetros
puedes cambiar en el algoritmo y experimenta cambiándolos (cuánta repulsión, rigidez
de los resortes, número de iteraciones, etc.)


Otras familias de algoritmos intentan distintas estrategias, como los layout
de círculo, estrella, para árboles, etc.


```r
ggraph(g, layout = 'circle') +
  geom_edge_link() +
  geom_node_point(size = 2, colour = 'salmon') +
  theme_graph()
```

<img src="06-pagerank_files/figure-html/unnamed-chunk-9-1.png" width="576" />

## Medidas de centralidad para redes

Como discutimos arriba, las medidas de centralidad en redes intentan capturar
un concepto de importancia o conectividad de un nodo en una red. Primero comenzamos
con el caso **no dirigido**. Medidas básicas de centralidad son


- **Grado** o grado de entrada/salida: cuántas ligas tiene un nodo (no dirigidos, de entrada o de salida). 

- **Betweeness**: qué tan importante o único es un nodo para conectar otros pares
de nodos de la red (por ejemplo, una persona con betweeness alto controla más fácilmente el flujo de información en una red social). 

- **Cercanía**: qué tan lejos en promedio están los otros nodos de la red (pues puede encontrar y conectar más fácilmente otras dos nodos en la red).

- **Centralidad de eigenvector/Pagerank**: la centralidad de un nodo es una especie de promedio de la centralidad de sus vecinos.

### Grado

Sea $G$ una gráfica **no dirigida**, y sea $A$ la matriz de adyacencia de $G$.
Si $i$ es un nodo (vértice) dado, entonces su grado es

$$c_G(i)=\sum_{j\neq i} A_{i,j}.$$
que cuenta cúantas aristas conectan con el nodo $i$.


```r
graficar_red_nd <- function(dat_g, layout = 'kk'){
  ggraph(dat_g, layout = layout) +
  geom_edge_link(alpha=0.2) +
  geom_node_point(aes(size = importancia), colour = 'salmon') +
  geom_node_text(aes(label = nombre), nudge_y = 0.2, size=3) +
  theme_graph(base_family = 'sans')
}

g_grado <- g |> activate(nodes) |>
  mutate(importancia = centrality_degree()) |>
  mutate(nombre = 1:20) 

graficar_red_nd(g_grado)
```

<img src="06-pagerank_files/figure-html/unnamed-chunk-10-1.png" width="672" />


#### ¿Qué no captura el grado como medida de centralidad? {-}

\BeginKnitrBlock{resumen}<div class="resumen">El **grado** es una medida local que no toma en cuenta la topología más global
de la red: cómo están conectados nodos más lejanos alrededor del nodo que nos interesa.</div>\EndKnitrBlock{resumen}

#### Distancia a otros nodos {-}

En primer lugar, por ejemplo, no captura que algunos nodos están más cercanos en 
promedio a los nodos de la red que otros.


```r
g_simple <- igraph::graph(c(1, 2, 2, 3, 3, 4, 4, 5), directed = FALSE) |> 
  as_tbl_graph() |>
  mutate(importancia = centrality_degree()) |>
  mutate(nombre  = LETTERS[1:5])
graficar_red_nd(g_simple)
```

<img src="06-pagerank_files/figure-html/unnamed-chunk-12-1.png" width="672" />

Obsérvese en este ejemplo que el nodo $C$ es más importante que $D$, en el sentido
de que está más cercano a los nodos de toda la red, aún cuando el grado es el mismo
para ambos.


#### Caminos que pasan por un nodo {-}

En la siguiente gráfica, el nodo $G$ es importante porque es la única conexión
entre dos partes de la red, y esto no lo captura el grado:


```r
triangulo_1 <- c(1,2,2,3,3,1)
triangulo_2 <- triangulo_1 + 3
red_3 <- igraph::graph(c(triangulo_1, triangulo_2, c(7,1,7,4)), directed = FALSE) |> 
  as_tbl_graph() |>
  mutate(importancia = centrality_degree()) |>
  mutate(nombre  = LETTERS[1:7])
graficar_red_nd(red_3)
```

<img src="06-pagerank_files/figure-html/unnamed-chunk-13-1.png" width="672" />

#### Nodos conectados a otros nodos importantes {-}

En la siguiente gráfica el nodo $H$ tienen el mismo grado que $F$, pero
$H$ está conectado a un nodo más importante ($A$)

```r
red_4 <- igraph::graph(c(2,1,3,1,4,1,5,1,2,3,6,2,1,7,1,8), directed=FALSE) |> 
  as_tbl_graph() |>
  mutate(importancia = centrality_degree()) |>
  mutate(nombre  = LETTERS[1:8])
graficar_red_nd(red_4)
```

<img src="06-pagerank_files/figure-html/unnamed-chunk-14-1.png" width="672" />


### Medida de centralidad: *Betweeness* o *Intermediación*

La medida de centralidad de *intermediación* de un nodo $u$ se define como:
$$c_b (u) = \sum_{j<k, u\neq j,u\neq i} \frac{ g(j,k |u)}{ g(j,k)},$$
donde

- $g(j,k)$ es el número de caminos más cortos distintos entre $j$ y $k$ y 
- $g(j,k |u)$ es el número de caminos más cortos distintos entre $j$ y $k$ que pasan por $u$. 
- $g(j,k | u ) = 0$ cuando $j=u$ o $k=u$.

- Los caminos que más aportan a la intermediación de un nodo $u$ son aquellos que
conectan nodos que no tienen otra alternativa más que pasar por $u$.

Esta medida se puede normalizar poniendo ($n$ es el total de nodos de la red)
$$\overline{c}_b (i)=c_b (i)/\binom{n-1}{2},$$
pues el denominador es el máximo valor de intermediación que puede alcanzar un vértice
en una red de $n$ nodos (demuéstralo). 

#### Ejemplo {-}


```r
red_4 <- igraph::graph(c(2,1,3,1,4,1,5,1,2,3,6,2,2,5,1,6,6,7), 
        directed = FALSE) |> 
  as_tbl_graph() |>
  mutate(importancia = centrality_betweenness()) |>
  mutate(nombre  = LETTERS[1:7])
graficar_red_nd(red_4) + labs(subtitle = 'Intermediación')
```

<img src="06-pagerank_files/figure-html/unnamed-chunk-15-1.png" width="384" />

Por ejemplo, consideremos el nodo $B$. Hay dos caminos más
cortos de $C$ a $F$ (de tamaño $2$), y uno de ellos pasa por $B$. 
De modo que los caminos de $C$ a $F$ aportan $0.5$ al *betweeness*
de $B$. De los caminos más cortos entre $E$ y $D$, ninguno pasa
por $B$, así que este par de vértices aporta $0$ al *betweeness*.
Verifica el valor de betweeness para $B$ haciendo los cálculos
restantes:



```r
red_4 |> as_tibble()
```

```
## # A tibble: 7 × 2
##   importancia nombre
##         <dbl> <chr> 
## 1         7.5 A     
## 2         2.5 B     
## 3         0   C     
## 4         0   D     
## 5         0   E     
## 6         5   F     
## 7         0   G
```

#### Ejemplo de grado e intermediación: Pulp Fiction {-}

En esta red, el color es una medición de betweeness y el tamaño del nodo una medición del grado.
Aunque Butch y Jules tienen grados similares, Butch tiene *intermediación* más alto
pues provee más ligas únicas más cortas 
entre los personajes, mientras que la mayoría de los de Jules
pasan también por Vincent.

![Pulp fiction](./images/pulp_fiction_between.png)


### Medida de centralidad: Cercanía

También es posible definir medidas de importancia según el promedio de cercanía a todos
los nodos. Éste se calcula como el inverso del promedio de distancias del nodo a todos los demás.

#### Ejemplo {-}

```r
red_5 <- igraph::graph(c(2,1,3,1,4,9,5,2,2,3,6,1,7,8,
                 8,9,9,1,1,8,1,7), 
               directed = FALSE)
```


```r
red_5 <- red_5 |> as_tbl_graph() |>
  mutate(importancia = centrality_closeness(normalized = TRUE)) |>
  mutate(nombre  = LETTERS[1:9])
red_5 |> activate(nodes) |> as_tibble()
```

```
## # A tibble: 9 × 2
##   importancia nombre
##         <dbl> <chr> 
## 1       0.8   A     
## 2       0.571 B     
## 3       0.533 C     
## 4       0.381 D     
## 5       0.381 E     
## 6       0.471 F     
## 7       0.5   G     
## 8       0.571 H     
## 9       0.571 I
```

```r
graficar_red_nd(red_5) + labs(subtitle = 'Cercanía')
```

<img src="06-pagerank_files/figure-html/unnamed-chunk-18-1.png" width="672" />

En este ejemplo, el nodo $F$ tiene cercanía más alta que $D$, por ejemplo,
pues se conecta a un nodo bien conectado de la red (en grado y betweeness):

#### Ejercicio {-}
Verifica que la cercanía de $A$ es $0.80$.

### Centralidad de eigenvector

Esta medida considera que la importancia de un nodo está dado por la suma 
normalizada de las
importancias de sus vecinos. De esta forma, es importante estar cercano a nodos importantes (como en cercanía), pero también cuenta conectarse a muchos nodos (como en grado).

- Nótese que esta es una descripción circular: para saber la importancia de un nodo, hay que saber la importancia de sus vecinos.

Consideremos el ejemplo siguiente:



```r
red_6 <- igraph::graph(c(1,2,1,3,1,4,5,2), directed = FALSE) |>
  as_tbl_graph() |> mutate(nombre = 1:5, importancia = 0)
graficar_red_nd(red_6) + theme(legend.position="none")+ labs(subtitle = 'Eigenvector')
```

<img src="06-pagerank_files/figure-html/unnamed-chunk-19-1.png" width="672" />

Supongamos que las importancias de estos $5$ nodos son
$$(x_1,\ldots, x_5)$$
donde $x_i\geq 0$. Suponemos también que estas importancias
están normalizadas, de forma que $\sum_i x_i = 1$.

De acuerdo a la idea mencionada arriba, calculamos entonces cómo se ve la suma de las importancias de nodos adyacentes a cada nodo. Para el nodo uno,

$${y_1} = x_2 + x_3 + x_4$$



para el nodo $2$ 

$$y_2 = x_1 + x_5$$

y para los siguientes nodos tendríamos
$$y_3 =  x_1$$
$$y_4 =  x_1$$
$$y_5 = x_2$$.

Este sistema lo podemos escribir de forma matricial, usando
la matriz de adyacencia, como

\[ y = 
\left (
\begin{array}{rrrrr}
 0 & 1 & 1 & 1 & 0 \\ 
 1 & 0 & 0 & 0 & 1 \\ 
  1 & 0 & 0 & 0 & 0 \\ 
  1 & 0 & 0 & 0 & 0 \\ 
  0 & 1 & 0 & 0 & 0 \\ 
\end{array}
\right ) x
\]


**Por definición de las importancias**, tenemos que normalizar este vector $y$ para obtener importancias originales. Es decir, existe una $\lambda$ tal que

$$\frac{1}{\lambda}y = x$$

Donde $\lambda\geq 0$ es el factor de normalización. En resumen, $x\geq 0$ debe satisfacer, para alguna $\lambda > 0$, la
ecuación 
$$A^t x = \lambda x,$$

es decir, $x$ **es un vector propio de la matriz de adyacencia con valor propio positivo.**

Sin embargo, ¿cuando existe un vector $x\geq 0$ con $\lambda>0$ que satisfaga esta propiedad? ¿es único?

#### Ejercicio {-}
Resuelve el sistema de ecuaciones de arriba y verifica que tal vector existe.
¿Cuál es el valor de lambda?

#### Matrices no negativas {-}

Para entender la existencia y forma de la centralidad de eigenvector,
comenzamos recordando algunos teoremas básicos de álgebra lineal. En primer
lugar, tenemos:

\BeginKnitrBlock{resumen}<div class="resumen">**Espectro de matrices no-negativas**

Si $A$ es una matriz no negativa,  entonces:

- Existe un valor
propio real *no-negativo* $\lambda_0$ tal que $\lambda_0\geq |\lambda|$ para cualquier otro valor propio $\lambda$ de $A$. 
- Al valor propio $\lambda_0$ está asociado al menos un vector propio $x$ con entradas no negativas. </div>\EndKnitrBlock{resumen}

Nota: Parte de este teorema se puede entender observando que si $A$ es no-negativa, entonces
mapea el cono $\{(x_1,x_2,\ldots, x_m) | x_i \geq 0\}$ dentro de sí mismo,
lo que implica que debe dejar invariante alguna dirección dentro de este cono.

Si este vector propio no-negativo fuera único (hasta normalización) y distinto del
vector $0$, entonces esto nos daría un conjunto de medidas (únicas hasta normalización) $x$ para la importancia de los nodos:

#### Ejemplo 1 {-}


```r
par(mar=c(0,0,0,0)); plot(red_6, vertex.size = 40)
```

<img src="06-pagerank_files/figure-html/unnamed-chunk-21-1.png" width="200px" height="200px" />

```r
A_red <- igraph::get.adjacency(red_6)
A_red
```

```
## 5 x 5 sparse Matrix of class "dgCMatrix"
##               
## [1,] . 1 1 1 .
## [2,] 1 . . . 1
## [3,] 1 . . . .
## [4,] 1 . . . .
## [5,] . 1 . . .
```



```r
desc_A <- eigen(A_red)
print(desc_A, digits = 2)
```

```
## eigen() decomposition
## $values
## [1]  1.85  0.77  0.00 -0.77 -1.85
## 
## $vectors
##      [,1]  [,2]     [,3]  [,4]  [,5]
## [1,] 0.65 -0.27  0.0e+00  0.27  0.65
## [2,] 0.50  0.50 -8.2e-17  0.50 -0.50
## [3,] 0.35 -0.35  7.1e-01 -0.35 -0.35
## [4,] 0.35 -0.35 -7.1e-01 -0.35 -0.35
## [5,] 0.27  0.65  0.0e+00 -0.65  0.27
```

Las medida de centralidad de eigenvector da entonces, en este caso:


```r
x <- desc_A$vectors[,1]
print(x, digits = 2)
```

```
## [1] 0.65 0.50 0.35 0.35 0.27
```

```r
par(mar=c(0,0,0,0)); plot(red_6, vertex.size  = 100*x)
```

<img src="06-pagerank_files/figure-html/unnamed-chunk-23-1.png" width="200px" height="200px" />


#### Ejemplo 2 {-}

Sin embargo, puede ser que obtengamos más de un valor propio no negativo con
vectores asociados no negativos, por ejemplo:



```r
red <- igraph::graph(c(1,2,2,3,3,1,2,4,5,6), directed = FALSE)
par(mar=c(0,0,0,0)); plot(red, vertex.size=20)
```

<img src="06-pagerank_files/figure-html/unnamed-chunk-24-1.png" width="200px" height="200px" />

```r
A_red <- igraph::get.adjacency(red)
A_red
```

```
## 6 x 6 sparse Matrix of class "dgCMatrix"
##                 
## [1,] . 1 1 . . .
## [2,] 1 . 1 1 . .
## [3,] 1 1 . . . .
## [4,] . 1 . . . .
## [5,] . . . . . 1
## [6,] . . . . 1 .
```


Nótese que los eigenvectores $1$ y $2$ son no negativos, y están asociados a 
vectores propios no negativos:

```r
desc_A <- eigen(A_red)
print(desc_A, digits = 2)
```

```
## eigen() decomposition
## $values
## [1]  2.17  1.00  0.31 -1.00 -1.00 -1.48
## 
## $vectors
##       [,1] [,2]  [,3]  [,4]     [,5]  [,6]
## [1,] -0.52 0.00 -0.37  0.00 -7.1e-01  0.30
## [2,] -0.61 0.00  0.25  0.00  2.2e-16 -0.75
## [3,] -0.52 0.00 -0.37  0.00  7.1e-01  0.30
## [4,] -0.28 0.00  0.82  0.00  6.7e-16  0.51
## [5,]  0.00 0.71  0.00  0.71  0.0e+00  0.00
## [6,]  0.00 0.71  0.00 -0.71  0.0e+00  0.00
```

**Nota**: si encontramos un vector propio $x$ con entradas negativas o cero,
podemos convertirlo a un vector propio con entradas no negativas tomando $-x$. Los
vectores propios debemos considerarlos *módulo* una constante multiplicativa, y 
los vectores particulares que se encuentran dependen del algoritmo.

En este caso, la medida de centralización dependería de qué
peso le ponemos al primer vector propio vs el segundo vector propio. En este
ejemplo, la unicidad no sucede pues la red asociada no es conexa.

### Matrices irreducibles y gráficas fuertemente conexas {-}

¿Cuándo podemos garantizar unicidad en la solución de $Ax=\lambda x$ con $\lambda >0$ y que $x$ sea un vector no-negativo distinto de $0$?

Sea $A$ la matriz de adyacencia de una gráfica **no dirigida**.
  
-  Si la gráfica asociada a $A$ es fuertemente conexa (existen caminos entre cualquier par de vértices) entonces decimos que $A$ es **irreducible**.
- Podemos dar también una definición de irreducibilidad sólo en términos
de $A$: $A$ es irreducible cuando para toda $i,j$ existe $m\geq 0$ tal
que $(A^m)_{i,j} > 0$.

*Nota*: discute por qué estas dos definiciones son equivalentes.

Utilizaremos uno de los teoremas más importantes del
álgebra lineal:


\BeginKnitrBlock{resumen}<div class="resumen">**Teorema de Perron-Frobenius**
  
Si $A$ es una matriz no-negativa irreducible, entonces

- Existe un valor
propio real *positivo* simple $\lambda_0$ tal que $\lambda_0 > |\lambda|$ para cualquier otro valor propio $\lambda$ de $A$, asociado a un vector propio $x$ con entradas positivas.
- No existe ningún otro vector propio con entradas no negativas que no sea paralelo a $x$.</div>\EndKnitrBlock{resumen}

Y entonces podemos definir una medida única de centralidad módulo una constante multiplicativa.

\BeginKnitrBlock{resumen}<div class="resumen">Si $A$ es la matriz de adyacencia de una red no dirigida, y $A$ es irreducible (significa que la red es fuertemente conexa), definimos
la **centralidad de eigenvector** de un nodo $i$ como la $i$-esima componente
del vector positivo $x$ (con $\sum x_i = 1$)
asociado al valor propio (único) de Perron-Frobenius. </div>\EndKnitrBlock{resumen}

#### Ejemplo: facultad de tres universidades {-}


```r
install.packages('igraphdata')
```

```
## Installing package into '/usr/local/lib/R/site-library'
## (as 'lib' is unspecified)
```

```r
library("igraphdata")
data("UKfaculty")
ukf.und <- igraph::as.undirected(UKfaculty) 
head(dat_1 <- igraph::get.data.frame((ukf.und)))
```

```
##   from to weight
## 1    1  4      4
## 2    3  4      1
## 3    5  6      1
## 4    5  7      2
## 5    6  7     28
## 6    3  9      1
```

```r
grupo <- igraph::get.vertex.attribute(UKfaculty, 'Group')
nodos <- data.frame(id = 1:length(grupo))

visNetwork(nodos, dat_1, width = "100%") |>
  visPhysics(solver ='forceAtlas2Based', 
             forceAtlas2Based = list(gravitationalConstant = -10),
             stabilization = TRUE)
```

```{=html}
<div id="htmlwidget-3fdcfbf7f2507f698e36" style="width:100%;height:480px;" class="visNetwork html-widget"></div>
<script type="application/json" data-for="htmlwidget-3fdcfbf7f2507f698e36">{"x":{"nodes":{"id":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81]},"edges":{"from":[1,3,5,5,6,3,4,5,5,7,5,7,5,7,10,12,2,14,5,7,12,13,3,4,9,2,7,15,15,18,2,6,8,14,15,18,19,2,8,10,13,15,19,5,7,10,12,21,5,7,10,12,13,22,2,15,20,21,2,14,20,21,5,7,10,13,16,19,22,23,5,10,13,2,4,6,7,8,14,15,18,19,20,21,22,23,24,26,27,6,7,10,22,2,8,15,19,20,21,25,26,29,2,24,29,31,10,12,13,16,23,27,15,19,21,25,29,31,2,15,18,21,26,27,29,31,34,1,3,4,2,5,7,9,10,13,15,16,18,19,21,26,27,29,31,32,33,34,35,1,2,5,10,17,33,37,2,15,18,19,21,25,29,31,5,7,10,12,16,23,27,33,37,2,8,15,20,21,29,31,35,5,7,10,16,23,27,28,33,37,39,2,8,12,13,15,18,19,21,25,29,31,34,35,37,41,1,36,1,4,9,17,36,38,44,2,11,15,18,19,21,29,31,34,35,39,43,6,7,22,25,28,5,24,27,37,5,10,12,13,23,27,33,37,42,5,6,18,21,29,35,37,38,43,2,14,15,18,20,21,26,29,31,37,43,1,2,5,9,18,21,24,26,27,29,32,33,35,37,43,48,49,50,3,4,9,17,36,44,49,2,15,17,19,20,25,26,29,34,35,37,38,39,43,46,48,50,51,52,24,29,32,37,48,52,14,20,26,51,55,2,15,18,19,29,31,35,37,39,43,46,51,52,6,11,15,18,19,21,22,27,29,34,35,37,39,46,50,51,54,3,9,17,38,4,9,37,43,1,3,4,5,9,17,45,53,59,1,2,7,9,10,17,18,21,23,24,25,27,29,31,32,37,42,44,46,49,52,54,55,57,61,7,27,30,47,62,5,24,29,32,37,48,52,55,62,5,10,16,27,40,42,62,6,22,29,30,5,27,37,48,58,5,6,7,10,12,13,16,23,27,28,33,40,42,49,66,5,6,7,10,12,13,18,22,23,27,28,29,33,35,37,40,42,47,49,52,59,62,68,2,21,29,37,48,49,50,52,54,57,62,69,10,16,29,33,40,42,69,5,6,7,10,13,16,33,40,42,49,69,38,4,36,38,59,61,62,4,17,38,52,53,61,62,74,5,10,22,42,49,58,62,72,5,7,10,12,13,16,22,23,27,28,29,33,37,40,42,47,49,52,62,63,65,68,69,70,71,72,76,4,17,38,45,59,2,15,18,19,21,29,31,35,37,39,43,46,54,57,62,2,14,15,20,26,29,51,54,56,62,1,37,38,59,73,74,75],"to":[4,4,6,7,7,9,9,9,10,10,12,12,13,13,13,13,15,15,16,16,16,16,17,17,17,18,18,18,19,19,20,20,20,20,20,20,20,21,21,21,21,21,21,22,22,22,22,22,23,23,23,23,23,23,25,25,25,25,26,26,26,26,27,27,27,27,27,27,27,27,28,28,28,29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,30,30,30,30,31,31,31,31,31,31,31,31,31,32,32,32,32,33,33,33,33,33,33,34,34,34,34,34,34,35,35,35,35,35,35,35,35,35,36,36,36,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,38,38,38,38,38,38,38,39,39,39,39,39,39,39,39,40,40,40,40,40,40,40,40,40,41,41,41,41,41,41,41,41,42,42,42,42,42,42,42,42,42,42,43,43,43,43,43,43,43,43,43,43,43,43,43,43,43,44,44,45,45,45,45,45,45,45,46,46,46,46,46,46,46,46,46,46,46,46,47,47,47,47,47,48,48,48,48,49,49,49,49,49,49,49,49,49,50,50,50,50,50,50,50,50,50,51,51,51,51,51,51,51,51,51,51,51,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,53,53,53,53,53,53,53,54,54,54,54,54,54,54,54,54,54,54,54,54,54,54,54,54,54,54,55,55,55,55,55,55,56,56,56,56,56,57,57,57,57,57,57,57,57,57,57,57,57,57,58,58,58,58,58,58,58,58,58,58,58,58,58,58,58,58,58,59,59,59,59,60,60,60,60,61,61,61,61,61,61,61,61,61,62,62,62,62,62,62,62,62,62,62,62,62,62,62,62,62,62,62,62,62,62,62,62,62,62,63,63,63,63,63,64,64,64,64,64,64,64,64,64,65,65,65,65,65,65,65,66,66,66,66,67,67,67,67,67,68,68,68,68,68,68,68,68,68,68,68,68,68,68,68,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,70,70,70,70,70,70,70,70,70,70,70,70,71,71,71,71,71,71,71,72,72,72,72,72,72,72,72,72,72,72,73,74,74,74,74,74,74,75,75,75,75,75,75,75,75,76,76,76,76,76,76,76,76,77,77,77,77,77,77,77,77,77,77,77,77,77,77,77,77,77,77,77,77,77,77,77,77,77,77,77,78,78,78,78,78,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,80,80,80,80,80,80,80,80,80,80,81,81,81,81,81,81,81],"weight":[4,1,1,2,28,1,1,1,12,8,1,1,12,18,2,6,8,1,1,1,8,22,8,1,1,26,1,2,2,3,1,2,1,24,1,1,2,10,3,2,4,2,12,1,1,6,4,2,1,10,4,10,1,4,6,2,2,1,2,30,28,1,4,10,12,10,2,1,2,32,1,14,10,14,1,6,20,1,1,6,8,28,1,28,12,2,1,6,6,14,4,1,6,6,24,2,10,1,32,1,2,30,1,24,1,1,3,2,18,28,2,6,4,1,6,1,22,1,22,8,1,12,1,1,20,30,1,6,2,1,8,6,1,3,1,2,1,1,3,2,3,1,8,8,8,3,10,1,2,1,1,1,1,1,6,14,1,2,6,26,8,4,20,8,1,1,1,1,24,1,2,28,1,1,14,1,2,8,1,22,1,4,4,32,1,1,2,8,2,3,1,4,1,3,1,6,1,10,2,1,24,10,6,1,4,1,8,6,6,1,1,1,18,1,1,16,1,6,26,12,12,10,8,4,2,10,2,1,12,2,2,16,8,1,2,1,3,2,22,26,20,2,1,1,8,1,1,2,16,7,8,16,8,12,1,12,1,4,12,20,14,10,6,1,1,1,6,10,1,1,1,1,8,4,4,4,1,2,12,8,16,8,3,4,1,1,2,4,1,1,1,5,6,2,1,4,3,7,1,1,14,1,1,6,3,1,24,3,4,2,1,1,1,8,3,24,26,22,5,1,2,10,1,1,8,10,1,8,2,26,6,1,8,1,1,3,16,4,1,1,6,2,1,1,1,1,4,2,12,3,2,1,12,1,2,20,1,1,12,2,6,1,1,3,14,1,1,4,2,1,1,1,1,3,5,1,10,3,1,26,3,1,1,1,1,8,2,4,1,1,1,1,24,1,1,12,2,20,1,1,3,2,18,12,22,2,1,6,3,2,1,4,1,20,6,1,6,10,2,1,1,2,24,16,8,18,2,6,1,3,10,1,6,2,1,8,1,2,1,3,24,6,1,1,2,16,16,1,14,2,4,3,1,18,1,10,2,1,4,10,1,8,3,10,1,1,18,1,3,4,14,1,10,2,2,8,6,8,2,1,1,6,1,1,12,10,2,10,1,2,4,10,16,8,2,2,2,26,1,1,1,10,10,22,28,2,24,2,28,1,10,1,4,10,16,6,10,16,2,1,10,6,1,1,6,3,4,8,12,10,3,1,14,1,8,20,1,8,14,1,18,3,1,2,5,8,2,1,18,20,14,30,28,1,1,2,8,1,2,1,1,18,1,30,24,1,12,1,10,2,1,1,5,12,22,16,2]},"nodesToDataframe":true,"edgesToDataframe":true,"options":{"width":"100%","height":"100%","nodes":{"shape":"dot"},"manipulation":{"enabled":false},"physics":{"solver":"forceAtlas2Based","stabilization":true,"forceAtlas2Based":{"gravitationalConstant":-10}}},"groups":null,"width":"100%","height":null,"idselection":{"enabled":false},"byselection":{"enabled":false},"main":null,"submain":null,"footer":null,"background":"rgba(0, 0, 0, 0)"},"evals":[],"jsHooks":[]}</script>
```



Ahora calculamos centralidad de eigenvector.


```r
A <- igraph::get.adjacency(ukf.und)
desc_A <- eigen(as.matrix(A))
desc_A$values
```

```
##  [1] 19.28427195 13.54891742  8.52732413  6.01906197  5.20390737  4.55975215
##  [7]  4.31365219  3.62893919  3.52142334  3.05024058  2.96600797  2.68231620
## [13]  2.39513555  2.31619056  2.16862613  2.16367314  1.86878695  1.79335793
## [19]  1.67210831  1.45711323  1.31398285  1.26342258  1.11860926  0.91192684
## [25]  0.83298297  0.76661085  0.67717797  0.62853503  0.60853711  0.53658897
## [31]  0.40633064  0.35269668  0.22890511  0.10925448  0.07019048 -0.10784969
## [37] -0.21375151 -0.29653588 -0.32269871 -0.53285114 -0.60927866 -0.67667658
## [43] -0.75224677 -0.89246427 -0.91320548 -0.98714368 -1.08654186 -1.17819491
## [49] -1.18780363 -1.24700384 -1.34884565 -1.40630820 -1.49500340 -1.55283728
## [55] -1.65998702 -1.69095896 -1.80343425 -1.95608850 -2.02372354 -2.17895021
## [61] -2.21010702 -2.26810495 -2.37069677 -2.43515105 -2.61093872 -2.66944398
## [67] -2.82823649 -2.89324478 -3.01642381 -3.17631366 -3.26214715 -3.33603214
## [73] -3.62535659 -3.80512720 -4.08174170 -4.35124493 -4.48050936 -4.88798336
## [79] -5.21384350 -5.34107403 -5.98245325
```


```r
vec <- as.numeric(desc_A$vector[,1])
desc_A$values[1]
```

```
## [1] 19.28427
```

```r
e_vector <- -vec
qplot(e_vector,xlab="Primer vector propio",main="Importancia por centralidad de eigenvector")+theme(plot.title = element_text(hjust=0.5))
```

```
## `stat_bin()` using `bins = 30`. Pick better value with `binwidth`.
```

<img src="06-pagerank_files/figure-html/unnamed-chunk-30-1.png" width="672" />


```r
colores <- colorRampPalette(c('red','green'))
colores_1 <- colores(length(e_vector))
nodos <- data.frame(id=1:length(vec), value = e_vector, 
                    color = colores_1[rank(e_vector)])

visNetwork(nodos, dat_1 |> select(-weight), 
           width = "100%") |>
  visPhysics(solver ='forceAtlas2Based', 
             stabilization = TRUE) |>
  visNodes(value = 1, scaling = list(min = 1, max = 200))
```

```{=html}
<div id="htmlwidget-16048b3035b71f1f7c2e" style="width:100%;height:480px;" class="visNetwork html-widget"></div>
<script type="application/json" data-for="htmlwidget-16048b3035b71f1f7c2e">{"x":{"nodes":{"id":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81],"value":[0.0306174407429767,0.175515197219491,0.0102271075866428,0.0285914950533414,0.160390263401205,0.0718943137621042,0.150381546237523,0.0479919957294216,0.0529114203592903,0.149802238238828,0.0136797536233053,0.0903581054978155,0.125751848164982,0.0428120626360817,0.158240096906385,0.0946747059933191,0.0347036292612618,0.156936332783759,0.131298684360442,0.0948068632871642,0.181974995552709,0.101401214279906,0.123351058326896,0.0484053694791653,0.0810798769999323,0.0989797993801854,0.177720458786087,0.0559874640829877,0.259525713522221,0.0282067007821213,0.151662578282076,0.0746256077101075,0.117881951525235,0.103411653157381,0.1635696457486,0.00719450226198973,0.272264032422249,0.0697743259865613,0.110254171905723,0.104643772395937,0.0725097571317513,0.129746109023111,0.165010789262961,0.0146395679248355,0.014542458638919,0.13228971058163,0.0447731087396074,0.0675833650702721,0.129789214097383,0.109031007835389,0.118624989202183,0.186787354488398,0.0178300041561972,0.165787940090548,0.0630763500706515,0.0253261276592991,0.137143775639684,0.131514378490487,0.0228208419681995,0.0269015982796774,0.033170430895945,0.212129003283634,0.0409836396830248,0.0697349147003838,0.0625502165486277,0.0294827364753791,0.041975787330514,0.107525165656292,0.184559914614334,0.117153520499074,0.0631583729893612,0.086232099159597,0.00484230057423121,0.0222926640576147,0.0326112815657097,0.0662785382110072,0.177128835293224,0.00883791471909327,0.133456045129409,0.0700958686299678,0.0236059151474761],"color":["#CC3300","#19E500","#F50900","#D22C00","#26D800","#8C7200","#32CC00","#B24C00","#AC5200","#36C800","#F20C00","#7C8200","#4FAF00","#B84600","#29D500","#798500","#C23C00","#2CD200","#46B800","#758900","#0FEF00","#6F8F00","#52AC00","#AF4F00","#827C00","#728C00","#13EB00","#A85600","#03FB00","#D52900","#2FCF00","#857900","#59A500","#6C9200","#23DB00","#FB0300","#00FF00","#926C00","#5F9F00","#699500","#897500","#4CB200","#1FDF00","#EB1300","#EF0F00","#3FBF00","#B54900","#996600","#49B500","#629C00","#56A800","#09F500","#E81600","#1CE200","#A25C00","#DB2300","#39C500","#42BC00","#E21C00","#D82600","#C53900","#06F800","#BF3F00","#956900","#A55900","#CF2F00","#BC4200","#659900","#0CF200","#5CA200","#9F5F00","#7F7F00","#FF0000","#E51900","#C83600","#9C6200","#16E800","#F80600","#3CC200","#8F6F00","#DF1F00"]},"edges":{"from":[1,3,5,5,6,3,4,5,5,7,5,7,5,7,10,12,2,14,5,7,12,13,3,4,9,2,7,15,15,18,2,6,8,14,15,18,19,2,8,10,13,15,19,5,7,10,12,21,5,7,10,12,13,22,2,15,20,21,2,14,20,21,5,7,10,13,16,19,22,23,5,10,13,2,4,6,7,8,14,15,18,19,20,21,22,23,24,26,27,6,7,10,22,2,8,15,19,20,21,25,26,29,2,24,29,31,10,12,13,16,23,27,15,19,21,25,29,31,2,15,18,21,26,27,29,31,34,1,3,4,2,5,7,9,10,13,15,16,18,19,21,26,27,29,31,32,33,34,35,1,2,5,10,17,33,37,2,15,18,19,21,25,29,31,5,7,10,12,16,23,27,33,37,2,8,15,20,21,29,31,35,5,7,10,16,23,27,28,33,37,39,2,8,12,13,15,18,19,21,25,29,31,34,35,37,41,1,36,1,4,9,17,36,38,44,2,11,15,18,19,21,29,31,34,35,39,43,6,7,22,25,28,5,24,27,37,5,10,12,13,23,27,33,37,42,5,6,18,21,29,35,37,38,43,2,14,15,18,20,21,26,29,31,37,43,1,2,5,9,18,21,24,26,27,29,32,33,35,37,43,48,49,50,3,4,9,17,36,44,49,2,15,17,19,20,25,26,29,34,35,37,38,39,43,46,48,50,51,52,24,29,32,37,48,52,14,20,26,51,55,2,15,18,19,29,31,35,37,39,43,46,51,52,6,11,15,18,19,21,22,27,29,34,35,37,39,46,50,51,54,3,9,17,38,4,9,37,43,1,3,4,5,9,17,45,53,59,1,2,7,9,10,17,18,21,23,24,25,27,29,31,32,37,42,44,46,49,52,54,55,57,61,7,27,30,47,62,5,24,29,32,37,48,52,55,62,5,10,16,27,40,42,62,6,22,29,30,5,27,37,48,58,5,6,7,10,12,13,16,23,27,28,33,40,42,49,66,5,6,7,10,12,13,18,22,23,27,28,29,33,35,37,40,42,47,49,52,59,62,68,2,21,29,37,48,49,50,52,54,57,62,69,10,16,29,33,40,42,69,5,6,7,10,13,16,33,40,42,49,69,38,4,36,38,59,61,62,4,17,38,52,53,61,62,74,5,10,22,42,49,58,62,72,5,7,10,12,13,16,22,23,27,28,29,33,37,40,42,47,49,52,62,63,65,68,69,70,71,72,76,4,17,38,45,59,2,15,18,19,21,29,31,35,37,39,43,46,54,57,62,2,14,15,20,26,29,51,54,56,62,1,37,38,59,73,74,75],"to":[4,4,6,7,7,9,9,9,10,10,12,12,13,13,13,13,15,15,16,16,16,16,17,17,17,18,18,18,19,19,20,20,20,20,20,20,20,21,21,21,21,21,21,22,22,22,22,22,23,23,23,23,23,23,25,25,25,25,26,26,26,26,27,27,27,27,27,27,27,27,28,28,28,29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,30,30,30,30,31,31,31,31,31,31,31,31,31,32,32,32,32,33,33,33,33,33,33,34,34,34,34,34,34,35,35,35,35,35,35,35,35,35,36,36,36,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,38,38,38,38,38,38,38,39,39,39,39,39,39,39,39,40,40,40,40,40,40,40,40,40,41,41,41,41,41,41,41,41,42,42,42,42,42,42,42,42,42,42,43,43,43,43,43,43,43,43,43,43,43,43,43,43,43,44,44,45,45,45,45,45,45,45,46,46,46,46,46,46,46,46,46,46,46,46,47,47,47,47,47,48,48,48,48,49,49,49,49,49,49,49,49,49,50,50,50,50,50,50,50,50,50,51,51,51,51,51,51,51,51,51,51,51,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,53,53,53,53,53,53,53,54,54,54,54,54,54,54,54,54,54,54,54,54,54,54,54,54,54,54,55,55,55,55,55,55,56,56,56,56,56,57,57,57,57,57,57,57,57,57,57,57,57,57,58,58,58,58,58,58,58,58,58,58,58,58,58,58,58,58,58,59,59,59,59,60,60,60,60,61,61,61,61,61,61,61,61,61,62,62,62,62,62,62,62,62,62,62,62,62,62,62,62,62,62,62,62,62,62,62,62,62,62,63,63,63,63,63,64,64,64,64,64,64,64,64,64,65,65,65,65,65,65,65,66,66,66,66,67,67,67,67,67,68,68,68,68,68,68,68,68,68,68,68,68,68,68,68,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,70,70,70,70,70,70,70,70,70,70,70,70,71,71,71,71,71,71,71,72,72,72,72,72,72,72,72,72,72,72,73,74,74,74,74,74,74,75,75,75,75,75,75,75,75,76,76,76,76,76,76,76,76,77,77,77,77,77,77,77,77,77,77,77,77,77,77,77,77,77,77,77,77,77,77,77,77,77,77,77,78,78,78,78,78,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,80,80,80,80,80,80,80,80,80,80,81,81,81,81,81,81,81]},"nodesToDataframe":true,"edgesToDataframe":true,"options":{"width":"100%","height":"100%","nodes":{"shape":"dot","value":1,"scaling":{"min":1,"max":200}},"manipulation":{"enabled":false},"physics":{"solver":"forceAtlas2Based","stabilization":true}},"groups":null,"width":"100%","height":null,"idselection":{"enabled":false},"byselection":{"enabled":false},"main":null,"submain":null,"footer":null,"background":"rgba(0, 0, 0, 0)"},"evals":[],"jsHooks":[]}</script>
```

Podemos calcular también usando *gggraph*:


```r
uk_tbl <- ukf.und |> as_tbl_graph() |>
  activate(nodes) |>
  mutate(nombre = row_number()) |>
  mutate(importancia = centrality_eigen())
ggraph(uk_tbl, layout = 'fr') +
  geom_edge_link(alpha=0.2) +
  geom_node_point(aes(size = importancia), colour = 'salmon') +
  theme_graph(base_family = 'sans')
```

<img src="06-pagerank_files/figure-html/unnamed-chunk-32-1.png" width="672" />




## Gráficas dirigidas

Estos conceptos pueden aplicarse también para gráficas dirigidas, cuando hay un concepto de dirección en las relaciones de los nodos.

- In degree, out degree.
- Betweenness puede definirse en función de caminos dirigidos.
- Cercanía también (in closeness, out closeness).
- Centralidad de eigenvector: misma idea, pero la matriz $A$ no es simétrica. En este caso, $A_{ij} = 1$ cuando hay una arista que va de $i$ a $j$.

Consideremos en particular cómo se calcula la centralidad de eigenvector para una red dirigida.


```r
set.seed(28011)
red_6 <- igraph::erdos.renyi.game(5, p.or.m=0.5, directed=T)
par(mar=c(0,0,0,0))
plot(red_6, vertex.size=40)
```

<img src="06-pagerank_files/figure-html/unnamed-chunk-33-1.png" width="200px" height="200px" />

Su matriz de adyacencia es no simétrica

```r
A <- igraph::get.adjacency(red_6)
A
```

```
## 5 x 5 sparse Matrix of class "dgCMatrix"
##               
## [1,] . . 1 1 1
## [2,] 1 . 1 . 1
## [3,] . 1 . . 1
## [4,] 1 1 . . .
## [5,] 1 1 . 1 .
```


Para este ejemplo, las ecuaciones de importancia son como sigue. Para el nodo $1$,
$$\lambda x_1 = x_2 + x_4 + x_5$$
para el nodo 5, por ejemplo, es
$$\lambda x_5 = x_1 + x_2 + x_3$$
y así sucesivamente.

Obsérvese que en cada ecuación se consideran las aristas *entrantes*, de forma que la ecuación del nodo $1$ requiere la columna $1$ de la matriz de adyacencia, el nodo $2$ la columna $2$, etc. Es decir, la ecuación que debemos resolver es

$$A^t x = \lambda x$$

En el ejemplo anterior,

```r
desc_A <- eigen(t(as.matrix(A)))
v <- desc_A$vectors[,1]
print(as.numeric(v / sum(v)), digits = 2)
```

```
## [1] 0.23 0.21 0.16 0.17 0.23
```


¿Cuándo podemos garantizar unicidad en la solución de $A^tx=\lambda x$ con $\lambda > 0$?

Sea $A$ la matriz de adyacencia de una gráfica dirigida. Igual que en el caso
de gráficas no dirigidas:

-  Si la gráfica asociada a $A$ es fuertemente conexa (para cualquier par de vértices hay caminos $i\to j$ y $j\to i$) entonces decimos que $A$ es **irreducible**.
- Igualmente, $A$ es irreducible si y sólo si para cualquier $i,j$ existe una
$m>0$ tal que $(A^m)_{i,j}>0$.

Y podemos igualmente aplicar Perron-Frobenius, de donde concluimos: 


\BeginKnitrBlock{resumen}<div class="resumen">Si $A$ es irreducible, entonces $\lambda_0 > 0$ es un eigenvector simple de $A$, un vector propio asociado $x$ tiene entradas positivas, y no existe ningún otro vector propio con entradas no negativas que no sea paralelo a $x$.</div>\EndKnitrBlock{resumen}


Y entonces podemos definir una medida única de centralidad módulo una constante multiplicativa.


### Ejemplos: ¿qué pasa si $A$ es no reducible? {-}

Hay distintas maneras en que la matriz no es reducible, y cada una
de ellas contradice algún aspecto del teorema de Perron Frobenius.

Por ejemplo, si la gráfica es conexa pero no fuertemente conexa,
podemos tener vectores propios no positivos (algunos nodos resultan
con peso $0$):


```r
red <- igraph::graph(c(1,2,2,3,3,4,4,3), directed = TRUE)
par(mar=c(0,0,0,0)); plot(red, vertex.size = 40)
```

<img src="06-pagerank_files/figure-html/unnamed-chunk-37-1.png" width="200px" height="200px" />

```r
A_red <- as.matrix(igraph::get.adjacency(red))
A_red
```

```
##      [,1] [,2] [,3] [,4]
## [1,]    0    1    0    0
## [2,]    0    0    1    0
## [3,]    0    0    0    1
## [4,]    0    0    1    0
```

```r
eigen(t(A_red))
```

```
## eigen() decomposition
## $values
## [1]  1 -1  0  0
## 
## $vectors
##           [,1]       [,2]          [,3]           [,4]
## [1,] 0.0000000  0.0000000  0.000000e+00  2.834322e-292
## [2,] 0.0000000  0.0000000  7.071068e-01  -7.071068e-01
## [3,] 0.7071068  0.7071068  1.581879e-17  -1.581879e-17
## [4,] 0.7071068 -0.7071068 -7.071068e-01   7.071068e-01
```

Si la gráfica es disconexa, podemos tener valores propios no 
simples con distintos
vectores propios no negativos:


```r
red <- igraph::graph(c(1,2,2,3,1,1,4,5,5,4), directed = TRUE)
par(mar=c(0,0,0,0)); plot(red, vertex.size = 20)
```

<img src="06-pagerank_files/figure-html/unnamed-chunk-38-1.png" width="200px" height="200px" />

```r
A_red <- as.matrix(igraph::get.adjacency(red))
A_red
```

```
##      [,1] [,2] [,3] [,4] [,5]
## [1,]    1    1    0    0    0
## [2,]    0    0    1    0    0
## [3,]    0    0    0    0    0
## [4,]    0    0    0    0    1
## [5,]    0    0    0    1    0
```

```r
eigen(t(A_red))
```

```
## eigen() decomposition
## $values
## [1]  1 -1  1  0  0
## 
## $vectors
##           [,1]       [,2]      [,3] [,4]           [,5]
## [1,] 0.0000000  0.0000000 0.5773503    0   0.000000e+00
## [2,] 0.0000000  0.0000000 0.5773503    0  5.010421e-292
## [3,] 0.0000000  0.0000000 0.5773503    1  -1.000000e+00
## [4,] 0.7071068  0.7071068 0.0000000    0   0.000000e+00
## [5,] 0.7071068 -0.7071068 0.0000000    0   0.000000e+00
```

O ningún valor propio positivo:

```r
red <- igraph::graph(c(1, 2, 2, 3), directed = TRUE)
par(mar=c(0,0,0,0)); plot(red, vertex.size = 20)
```

<img src="06-pagerank_files/figure-html/unnamed-chunk-39-1.png" width="200px" height="200px" />

```r
A_red <- as.matrix(igraph::get.adjacency(red))
A_red
```

```
##      [,1] [,2] [,3]
## [1,]    0    1    0
## [2,]    0    0    1
## [3,]    0    0    0
```

```r
print(eigen(t(A_red)), digits = 2)
```

```
## eigen() decomposition
## $values
## [1] 0 0 0
## 
## $vectors
##      [,1]    [,2]    [,3]
## [1,]    0   0e+00   0e+00
## [2,]    0  3e-292 -3e-292
## [3,]    1  -1e+00   1e+00
```



## Pagerank

Pagerank es una medida similar a la centralidad de eigenvector:

- La importancia de una página (nodo) es un promedio ponderado de las importancias de otras páginas que apuntan (ligan) hacia ella. 
- Diferencia: usamos **gráficas dirigidas**, y **distribuimos el peso de las aristas dependiendo
de cuántas ligas hacia afuera tiene una página**: es decir, la importancia de una página se diluye entre el número de ligas a sus hijos.

Esto tiene sentido pues si tenemos una página importante que apunta a pocas páginas,
debe dar más importancia a estas pocas páginas que si apuntara a muchas páginas.

Para una red dirigida de páginas de internet, definimos entonces su **matriz de transición** $M$
como sigue:

- $M_{ij} =1/k$ si la página $i$ tiene $k$ ligas hacia afuera, y una de ellas va a la página $j$
- $M_{ij} = 0$ en otro caso.

Intentaremos hacer algo similar a la centralidad de eigenvector, pero usando la matriz de transición en lugar de la matriz de adyacencia.

### Ejemplo {-}


```r
red_p <- igraph::graph(c(1,2,1,4,1,3,2,1,2,4,3,1,4,3,2,3))
par(mar=c(0,0,0,0))
plot(red_p, vertex.size=40, edge.curved=T, edge.arrow.size=0.5)
```

<img src="06-pagerank_files/figure-html/unnamed-chunk-40-1.png" width="200px" height="200px" />

La matriz de adyacencia no necesariamente es simétrica, pues la gráfica es dirigida:


```r
A <- igraph::get.adjacency(red_p)
A
```

```
## 4 x 4 sparse Matrix of class "dgCMatrix"
##             
## [1,] . 1 1 1
## [2,] 1 . 1 1
## [3,] 1 . . .
## [4,] . . 1 .
```


Y calculamos la matriz M, que es la matriz $A$ con los renglones normalizados por
su suma:

```r
M <- A / Matrix::rowSums(A)
M
```

```
## 4 x 4 sparse Matrix of class "dgCMatrix"
##                                             
## [1,] .         0.3333333 0.3333333 0.3333333
## [2,] 0.3333333 .         0.3333333 0.3333333
## [3,] 1.0000000 .         .         .        
## [4,] .         .         1.0000000 .
```

### La matriz $M$ es estocástica

A la matriz $M$ le llamamos una **matriz estocástica**, pues cada uno
de sus renglones son no negativos y suman $1$. Bajo este supuesto, es posible
demostrar otra versión del teorema de Perron Frobenius:

\BeginKnitrBlock{resumen}<div class="resumen">**Principio del Pagerank**

Supongamos que $M$ es irreducible, que en el caso dirigido quiere decir que la red
es *fuertemente conexa*: existe un camino *dirigido* entre cualquier par de vértices.

- Entonces el valor propio de Perron-Frobenius (simple) para $M^t$  es $\lambda_0=1$, y el único vector
propio no negativo (módulo longitud) es estrictamente positivo y asociado a $\lambda_0=1$.

Esto implica que si $r$ es el vector de importancias según pagerank, entonces $r$ debe satisfacer 

$$r_j = \sum_{i\to j}  \frac{r_i}{d_i}$$

donde la suma es sobre las ligas de entrada a $j$, y $d_i$ es el grado de salida del nodo $i$ (dividimos la importancia de $r_i$ sobre todas sus aristas de salida). En forma matricial, esto se escribe como:
$$M^tr = r.$$</div>\EndKnitrBlock{resumen}


#### Ejercicio {-}
Escribe las ecuaciones de las dos formas mostradas arriba para la 
red

```r
red_p 
```

```
## IGRAPH 266b1de D--- 4 8 -- 
## + edges from 266b1de:
## [1] 1->2 1->4 1->3 2->1 2->4 3->1 4->3 2->3
```



#### Ejemplo: pagerank simple {-}

```r
decomp <- eigen(t(as.matrix(M)))
decomp
```

```
## eigen() decomposition
## $values
## [1]  1.0000000+0.0000000i -0.3333333+0.4714045i -0.3333333-0.4714045i
## [4] -0.3333333+0.0000000i
## 
## $vectors
##              [,1]                  [,2]                  [,3]             [,4]
## [1,] 0.6902685+0i  0.7071068+0.0000000i  0.7071068+0.0000000i  7.071068e-01+0i
## [2,] 0.2300895+0i -0.2357023-0.3333333i -0.2357023+0.3333333i -7.071068e-01+0i
## [3,] 0.6135720+0i -0.1571348+0.4444444i -0.1571348-0.4444444i -2.919335e-16+0i
## [4,] 0.3067860+0i -0.3142697-0.1111111i -0.3142697+0.1111111i -3.184729e-16+0i
```

```r
vec_1 <- abs(as.numeric(decomp$vector[,1]))
vec_1
```

```
## [1] 0.6902685 0.2300895 0.6135720 0.3067860
```

```r
round(vec_1/sum(vec_1), 2)
```

```
## [1] 0.38 0.12 0.33 0.17
```


```r
par(mar=c(0,0,0,0))
plot(red_p, vertex.size=100*vec_1, 
                          edge.curved=T, edge.arrow.size=0.5)
```

<img src="06-pagerank_files/figure-html/unnamed-chunk-46-1.png" width="200px" height="200px" />

¿Por qué $1$ tiene mayor importancia que $3$? Nótese que el nodo $3$ tiene mayor grado que $1$. La razón de
que el pagerank de $1$ es mayor que el de $3$ es que la importancia
del nodo $1$ se diluye pues tiene grado $3$ de salida, mientras
que toda la importancia de $3$ se comunica al nodo $1$.


### Primeras dificultades

¿Qué puede fallar cuando queremos encontrar el pagerank de un gráfica
que representa sitios de internet, por ejemplo? 
 
- Si existen **callejones sin salida** la matriz $M$ no es estocástica, pues tiene un renglón de ceros - no podemos aplicar la teoría de arriba. Por ejemplo, la siguiente matriz no tiene un valor propio igual a $1$ (conclusión invalidada: hay un valor propio igual a $1$):


```r
red_p <- igraph::graph(c(1,2,2,1,1,3))
par(mar=c(0,0,0,0)); plot(red_p, vertex.size=30, edge.curved=T,edge.arrow.size=0.5)
```

<img src="06-pagerank_files/figure-html/unnamed-chunk-47-1.png" width="200px" height="200px" />

```r
A <- igraph::get.adjacency(red_p)
M <- t(scale(t(as.matrix(A)), center=FALSE, scale=apply(A,1,sum)))
# ponemos cero porque ni siquiera se puede normalizar:
M[3, ]  <- 0
eigen(t(M))
```

```
## eigen() decomposition
## $values
## [1]  0.7071068 -0.7071068  0.0000000
## 
## $vectors
##           [,1]       [,2] [,3]
## [1,] 0.7071068  0.7071068    0
## [2,] 0.5000000 -0.5000000    0
## [3,] 0.5000000 -0.5000000    1
```

- Si existen **trampas de telaraña** (spider traps) entonces la matriz $M$ es estocástica, pero las soluciones concentran toda la importancia en la trampa (en este caso consiste de los nodos $1$ y $2$) (conclusión invalidada: el vector de importancias 
asociado al eigenvalor $1$ es positivo).


```r
red_p <- igraph::graph(c(1,2,2,1,3,1,3,4,4,5,5,3))
par(mar=c(0,0,0,0)); plot(red_p, vertex.size=30, edge.curved=T,edge.arrow.size=0.5)
```

<img src="06-pagerank_files/figure-html/unnamed-chunk-48-1.png" width="200px" height="200px" />

```r
A <- igraph::get.adjacency(red_p)
M <- t(scale(t(as.matrix(A)), center = FALSE, scale = apply(A,1,sum)))
eigen(t(M))
```

```
## eigen() decomposition
## $values
## [1]  1.0000000+0.0000000i -1.0000000+0.0000000i  0.7937005+0.0000000i
## [4] -0.3968503+0.6873648i -0.3968503-0.6873648i
## 
## $vectors
##              [,1]          [,2]          [,3]                  [,4]
## [1,] 0.7071068+0i -0.7071068+0i  0.4794851+0i  0.0242710-0.1851728i
## [2,] 0.7071068+0i  0.7071068+0i  0.6041134+0i -0.2173362+0.0901689i
## [3,] 0.0000000+0i  0.0000000+0i -0.4470916+0i  0.6699710+0.0000000i
## [4,] 0.0000000+0i  0.0000000+0i -0.2816501+0i -0.2110276-0.3655106i
## [5,] 0.0000000+0i  0.0000000+0i -0.3548568+0i -0.2658782+0.4605145i
##                       [,5]
## [1,]  0.0242710+0.1851728i
## [2,] -0.2173362-0.0901689i
## [3,]  0.6699710+0.0000000i
## [4,] -0.2110276+0.3655106i
## [5,] -0.2658782-0.4605145i
```

- La red puede ser **disconexa**.  Por ejemplo, cuando hay dos componentes irreducibles, existe más de un vector propio asociado al valor propio $1$ (conclusión invalidada: la solución es única y el valor propio $1$ es simple), así que hay tantas soluciones como combinaciones lineales de los eigenvectores que aparecen:


```r
red_p <- igraph::graph(c(1,2,2,3,3,1,4,5,5,6,6,5,6,4))
par(mar=c(0,0,0,0)); plot(red_p, vertex.size=30,
                          edge.curved=T,edge.arrow.size=0.5)
```

<img src="06-pagerank_files/figure-html/unnamed-chunk-49-1.png" width="200px" height="200px" />

```r
A <- igraph::get.adjacency(red_p) |> as.matrix()
M <- t(scale(t(A), center=FALSE, scale=apply(A,1,sum)))
M
```

```
##      [,1] [,2] [,3] [,4] [,5] [,6]
## [1,]    0    1    0  0.0  0.0    0
## [2,]    0    0    1  0.0  0.0    0
## [3,]    1    0    0  0.0  0.0    0
## [4,]    0    0    0  0.0  1.0    0
## [5,]    0    0    0  0.0  0.0    1
## [6,]    0    0    0  0.5  0.5    0
## attr(,"scaled:scale")
## [1] 1 1 1 1 1 2
```

```r
sol <- eigen(t(M))
sol
```

```
## eigen() decomposition
## $values
## [1]  1.0+0.0000000i -0.5+0.8660254i -0.5-0.8660254i  1.0+0.0000000i
## [5] -0.5+0.5000000i -0.5-0.5000000i
## 
## $vectors
##              [,1]            [,2]            [,3]          [,4]
## [1,] 0.0000000+0i  0.5773503+0.0i  0.5773503+0.0i -0.5773503+0i
## [2,] 0.0000000+0i -0.2886751-0.5i -0.2886751+0.5i -0.5773503+0i
## [3,] 0.0000000+0i -0.2886751+0.5i -0.2886751-0.5i -0.5773503+0i
## [4,] 0.3333333+0i  0.0000000+0.0i  0.0000000+0.0i  0.0000000+0i
## [5,] 0.6666667+0i  0.0000000+0.0i  0.0000000+0.0i  0.0000000+0i
## [6,] 0.6666667+0i  0.0000000+0.0i  0.0000000+0.0i  0.0000000+0i
##                       [,5]                  [,6]
## [1,]  0.0000000+0.0000000i  0.0000000+0.0000000i
## [2,]  0.0000000+0.0000000i  0.0000000+0.0000000i
## [3,]  0.0000000+0.0000000i  0.0000000+0.0000000i
## [4,]  0.3535534+0.3535534i  0.3535534-0.3535534i
## [5,]  0.3535534-0.3535534i  0.3535534+0.3535534i
## [6,] -0.7071068+0.0000000i -0.7071068+0.0000000i
```

```r
round(sol$values,2)
```

```
## [1]  1.0+0.00i -0.5+0.87i -0.5-0.87i  1.0+0.00i -0.5+0.50i -0.5-0.50i
```

```r
vec <- sol$vectors[,abs(sol$values-1) < 1e-8]
Re(vec)
```

```
##           [,1]       [,2]
## [1,] 0.0000000 -0.5773503
## [2,] 0.0000000 -0.5773503
## [3,] 0.0000000 -0.5773503
## [4,] 0.3333333  0.0000000
## [5,] 0.6666667  0.0000000
## [6,] 0.6666667  0.0000000
```


En términos de nuestra solución para dar importancia de páginas:

- No es razonable que nuestra solución concentre toda la importancia en spider traps.
- Si la gráfica es disconexa no podemos dar importancia relativa a las componentes resultantes.
- Si hay callejones sin salida entonces nuestra formulación no sirve.

---


Para encontrar una solución, podemos pensar en el proceso estocástico asociado a esta formulación de pagerank.

### El proceso estocástico (cadena de Markov) asociado al Pagerank, versión simple

Podemos interpretar este proceso mediante una cadena de Markov. 
Consideramos una persona que navega al azar en nuestra red (haciendo click
en las ligas disponibles en cada nodo):

- Comienza en una página tomada al azar (equiprobable).
- Cada vez que llega a una página, escoge al azar alguna de las páginas ligadas en su página actual y navega hacia ella.
- **Suponemos por el momento que no hay callejones sin salida** (estos evitan que pueda saltar a otro lado).

La pregunta que queremos contestar: **¿cuál es la probabilidad que en distintos
momentos el navegador aleatorio se encuentre en una página dada?** Claramente
páginas que tienen muchas ligas de entrada (son importantes) tendrán más visitas, y más aún
si estas ligas de entrada provienen de nodos con muchas ligas de entrada (es decir,
a su vez son importantes).  Sin embargo, es necesario hacer algunos refinamientos
si queremos contestar de manera simple esta pregunta.


Denotamos por $X_1, X_2,\ldots$ la posición del navegador en cada momento del tiempo. Cada $X_i$ es una variable aleatoria que toma valores en los nodos $\{1,2,\ldots,n\}$.


- $X_1, X_2,\ldots$ es un proceso estocástico discreto en tiempo discreto.
- Para determinar un proceso estocástico, debemos dar la distribución
conjunta de cualquier subconjunto $X_{s_1},X_{s_2},\ldots, X_{s_k}$ de variables. En este
caso, la posición en $s+1$ sólo depende de la posición en el momento $s$, de forma
que basta con especificar
$$P(X_{s+1}=j\vert X_s=i) = P_{ij}, $$
para cada par de páginas $i$ y $j$. 

### Matriz de transición

Ahora podemos ver que 

- Si hay una liga de $i$ a $j$, entonces $P_{ij}=1/k(i)$, donde $k(i)$ es el número
de ligas salientes de $i$.
- Si no  hay liga de $i$ a $j$, entonces $P_{ij}=0$.

Es claro que $P$ es igual a la matriz $M$ que definimos con anterioridad. 


### Distribución de equilibrio (versión simple)

La matriz $P$ es estocástica. Si suponemos que $P$ es irreducible (la gráfica es fuertemente conexa), entonces por la teoría que vimos arriba
existe un vector $\pi > 0$ tal que $P^t\pi = \pi$.

Ahora podemos interpretar este vector en términos del navegador aleatorio:

- En términos del modelo del navegador aleatorio, ¿ qué
significa entonces que un vector $\pi$ satisfaga $P^t \pi = \pi$, con $\pi \geq 0$?

Suponemos $\pi$ normalizado por la suma: $\sum_i \pi_i=1$.

- Significa que si escogemos un estado al azar con probabilidad $\pi$, entonces, después de un salto, las probabilidades de encontrar al navegador en cada estado está dado también por $\pi$. 
- Igualmente, la probabilidad de encontrar al navegador en cualquier momento en el estado $i$ es igual a $\pi_i$.
- Por esta razón, a $\pi$ se le llama una **distribución de equilibro** para
el proceso del navegador aleatorio.

### Distribución de equilibrio y probabilidades a largo plazo

Sin embargo, en un principio no conocemos la distribución de
equilibrio $\pi$. Lo que haríamos sería escoger un nodo al azar y comenzar
a navegar desde ahí, o quizá empezaríamos en un nodo fijo, por ejemplo, el $1$, y
nuestra pregunta sigue siendo **¿cuál es la probabilidad que en distintos
momentos el navegador aleatorio se encuentre en una página dada?**

En primer lugar, solamente con el supuesto de conexidad fuerte (irreducibilidad) 
no podemos contestar esta pregunta de manera simple. Esto es porque si 
no existe conexidad, entonces claramente los lugares donde podemos
encontrar al navegador depende de dónde empezó, y la respuesta es compleja. Veremos
que además, necesitamos un supuesto de aperiodicidad. 

Requerimos entonces:

- Conexidad fuerte (irreducibilidad)
- Aperiodicidad

Veremos ahora por qué la periodicidad puede ser un problema.

#### Ejemplo: periodicidad {-}

Consideremos este ejemplo fuertemente conexo (irreducible), con un ciclo de
tamaño $3$:


```r
red_p <- igraph::graph(c(1,2,2,3,3,1))
par(mar=c(0,0,0,0)); plot(red_p, vertex.size=30, edge.curved=T,edge.arrow.size=0.5)
```

<img src="06-pagerank_files/figure-html/unnamed-chunk-50-1.png" width="200px" height="200px" />

```r
A <- igraph::get.adjacency(red_p)
M <- t(scale(t(as.matrix(A)), center=FALSE, scale=apply(A,1,sum)))
M
```

```
##      [,1] [,2] [,3]
## [1,]    0    1    0
## [2,]    0    0    1
## [3,]    1    0    0
## attr(,"scaled:scale")
## [1] 1 1 1
```

Y notamos que si comenzamos en el estado uno, la probabilidad de estar en cada estado al tiempo $2$ es

```r
t(M) %*% c(1,0,0)
```

```
##      [,1]
## [1,]    0
## [2,]    1
## [3,]    0
```
En el tiempo $3$:

```r
t(M) %*% t(M) %*% c(1,0,0)
```

```
##      [,1]
## [1,]    0
## [2,]    0
## [3,]    1
```
En el tiempo $4$:

```r
t(M) %*% t(M) %*% t(M) %*% c(1,0,0)
```

```
##      [,1]
## [1,]    1
## [2,]    0
## [3,]    0
```
y así sucesivamente, de manera que las probabilidades de visita a cada nodo dependen 
siempre fuertemente del tiempo. La solución a nuestra pregunta de dónde
estará el navegador aleatorio al tiempo $t$ no es tan simple de
formular.

En este ejemplo, vemos que el problema son estructuras periódicas
en la red del navegador aleatorio. Veremos ahora cómo lidiar
con este problema.


### Matriz de transición a $k$ pasos

Recordamos que la matriz $(P)^k$ da las probabilidades de transición
a $k$ pasos. 

Por ejemplo, para $k=2$ tenemos la probabiildad de pasar de $i$ a $j$ en dos pasos es igual a (probabilidad total):

$$P(X_3=j|X_1=i) =\sum_k P(X_3=j|X_2=k, X_1=i) P(X_2=k|X_1=i)$$

Por la propiedad de Markov, podemos simplificar

$$P(X_3=j|X_1=i) =\sum_k P(X_3=j|X_2=k) P(X_2=k|X_1=i)$$

y si sustituimos $P$

$$P(X_3=j|X_1=i) =\sum_k P_{i,k} P_{k,j}. $$

Como el lado derecho es la componente $i,j$ de $P^2$, tenemos que
$P^2$ da las probabilidades de transición en $2$ pasos.

Como ejercicio, calcula e interpreta $P^2$ para el ejemplo anterior.

\BeginKnitrBlock{resumen}<div class="resumen">**Cadenas aperiódicas**
  
Decimos que $P$ irreducible es aperiódica cuando
$P^{k_0}>0$ para alguna $k_0$ suficientemente grande.</div>\EndKnitrBlock{resumen}

Nótese que en el ejemplo anterior $P$ no es aperiódica. Con esta condición (no importa en qué estado estamos al tiempo $k_0$ el navegador puede estar en cualquier estado), podemos dar una respuesta más simple a la pregunta acerca de las probabilidades de largo plazo de la cadena:

\BeginKnitrBlock{resumen}<div class="resumen">**Distribución a largo plazo**
  
Si $P$ es una matriz irreducible y aperiódica, y $\pi$ es su distribución de equilibrio, entonces 
$$\lim_{n\to \infty} P(X_n=i) = \pi_i,$$
independientemente de la distribución inicial.</div>\EndKnitrBlock{resumen}


Se puede demostrar ahora que, independiente de la distribución inicial,
si la distribución de equilibrio es $\pi$:

Sea $v$ una distribución inicial sobre los estados (cualquiera). Entonces, 
si $P$ es irreducible y aperiódica,
$$(P^n)^t v \to \pi$$
cuando $n\to \infty$.

Lo cual nos da el algoritmo básico para encontrar la importancia de Pagerank dada por la distribución de equilibrio:

\BeginKnitrBlock{resumen}<div class="resumen">**Método de potencias para pagerank simple**
  
Tomamos $v$ una distribución arbitraria (por ejemplo equidistribuida sobre los estados). Ponemos $v_1=v$ e iteramos
$$v_{n+1} = M^t v_{n}$$
hasta que $||v_{n+1} -v_{n}||<\epsilon.$</div>\EndKnitrBlock{resumen}

Veremos que este algoritmo simple es escalable a problemas muy grandes, pues
sólo involucra multiplicar por una matriz que típicamente es rala.

### Pagerank: teletransportación/perturbación de la matriz $M$

Para que funcione este algoritmo, como vimos antes, tenemos
que lidiar con los problemas que vimos arriba (spider traps, callejones sin salidas, falta de conexidad, periodicidad). 

La solución es relativamente simple: fijamos una $\alpha$ cercana a uno. A cada tiempo:

- Con probabilidad $\alpha$, el navegador escoge alguno de las ligas de salida y brinca (como en el proceso original),
- Sin embargo, con probabilidad $1-\alpha$, el navegador se teletransporta
a un nodo escogido al azar (equiprobable), de **todos** los nodos posibles.
- Si el navegador está en un callejón sin salida, siempre se teletransporta como en el inciso anterior.

Esta alteración del proceso elimina spider traps, callejones sin salidas, disconexiones y periodicidad.

Ahora construimos la matriz $M_1$ de este proceso. Sea $M$ la matriz original, que suponemos por el momento no tiene callejones sin salida.

¿Cómo se ven las nuevas probabildades de transición? Si $i,j$ son nodos, $n$ es el número total de nodos, tenemos simplemente (si $i$ no es spider-trap):

$$(M_1)_{i,j} = \alpha M_{ij} + (1-\alpha)\frac{1}{n}$$

Esto es por probabilidad total: la probabilidad de ir de $i$ a $j$ **dada** teletransportación es $1/n$, y la probabilidad de ir de $i$ a $j$ **dado** que no hubo teletransportación es $M_{ij}$ (que puede ser cero). La probabilidad total se calcula promediando estas dos probabilidades según la probabilidad de teletransportación o no.

Si $i$ es un spider-trap, entonces ponemos simplemente 
$$(M_1)_{i,j} = 1/n$$


- Idea: La matriz $M_1$ estocástica es positiva, de modo que automáticamente
es irreducible y aperiódica.

Tomando $\alpha=0.85$ obtenemos por ejemplo para nuestra matriz $M$ anterior:


```r
red.p <- igraph::graph(c(1,2,2,3,3,1,2,3,3,2,4,5,5,4))
par(mar=c(0,0,0,0)); plot(red.p, vertex.size=30, edge.curved=T,edge.arrow.size=0.5)
```

<img src="06-pagerank_files/figure-html/unnamed-chunk-57-1.png" width="672" />

```r
A <- igraph::get.adjacency(red.p)
M <- t(scale(t(as.matrix(A)), center=FALSE, scale=apply(A,1,sum)))
unos <- rep(1,nrow(M))
alpha <- 0.85
M.1 <- alpha*M + (1-alpha)*unos%*%t(unos)/nrow(M)
M.1
```

```
##       [,1]  [,2] [,3] [,4] [,5]
## [1,] 0.030 0.880 0.03 0.03 0.03
## [2,] 0.030 0.030 0.88 0.03 0.03
## [3,] 0.455 0.455 0.03 0.03 0.03
## [4,] 0.030 0.030 0.03 0.03 0.88
## [5,] 0.030 0.030 0.03 0.88 0.03
## attr(,"scaled:scale")
## [1] 1 2 2 1 1
```




```r
sol <- eigen(t(M.1))
sol$values
```

```
## [1]  1.000+0.000i -0.850+0.000i  0.850+0.000i -0.425+0.425i -0.425-0.425i
```

```r
as.numeric(sol$vectors[,1])
```

```
## [1] 0.2828726 0.5233143 0.5106595 0.4389488 0.4389488
```

#### Ejercicio {-}
Verifica que la matriz $M_1$ construida arriba es en realidad una matriz estocástica.

---

No es buena idea preprocesar desde el principio la matriz $M$ para evitar estos casos (la matriz $M$ es típicamente rala, pues hay relativamente pocas ligas en cada página comparado con el total de nodos, y no queremos llenar los renglones igual a cero con 
una cantidad fija). En lugar de eso, podemos hacer los siguiente:

Supongamos entonces que queremos calcular $x' = M_1 x$, tomando en cuenta callejones sin salida. Podemos hacer, para $x$ distribución inicial:

- Calcular $y = \alpha M^t x$ (operación con matriz rala).
- Nótese que los renglones de $M$ que son iguales a cero deben ser sustituidos por $1/N$ (callejones sin salida). Esto
implica que necesitamos sumar la misma cantidad a todas las entradas de $y$:
$$\frac{1}{N}\sum_{j\,es\, callejon} x_j$$.

- Por otra parte, para los que no son callejones, tenemos que sumar la cantidad fija
$$(1-\alpha)\frac{1}{N}\sum_{j\, no\, es\, callejon} x_j$$
- En cualquier caso, a todas las entradas se les suma una cantidad fija
$$\frac{1}{N}\sum_{j\,es\, callejon} x_j + (1-\alpha)\frac{1}{N}\sum_{j\, no\, es\, callejon} x_j,$$
y las componentes del vector resultante deben sumar uno.
- La estrategia de cálculo es entonces: una vez que tenemos $y$, simplemente ajustamos $x= y + (1-S)/N$, donde
$S=\sum_i y_i$, es decir: sumamos una cantidad fija para asegurar que suman uno las componentes de $x$.



### Pagerank para buscador


- Usamos índice invertido (términos a documentos) para escoger las páginas que son relevantes al query.
- Regresamos los resultados ordenados por el PageRank.

Consideramos las páginas de un solo sitio (universidad de Hollings):


```r
library(Matrix)
library(dplyr)
tab_1 <- read.table('../datos/data_hollings/hollins.txt')
write.csv(tab_1, file='../datos/data_hollings/ejemplo_red_hollings.csv', row.names=FALSE)
head(tab_1)
```

```
##   V1 V2
## 1  1  2
## 2  8  2
## 3 16  2
## 4 18  2
## 5 20  2
## 6 23  2
```

```r
i <- tab_1$V1
j <- tab_1$V2
x <- 1
```

Normalizamos y usamos estructura rala:

```r
mat <- data.frame(i=i, j=j, x=x)
mat_norm <- mat |> group_by(i) |>
  mutate(p = x / sum(x))
M <-sparseMatrix(i = mat_norm$i,
                 j = mat_norm$j,
                 x = mat_norm$p, 
                 dims = c(6012,6012))
dim(M)
```

```
## [1] 6012 6012
```

```r
sum(M>0)/6012^2
```

```
## [1] 0.0006605496
```


Nótese que hacer los cálculos con la matriz rala es más eficiente:


```r
library(microbenchmark)
r <- rep(1, 6012)/6012
M_t <- t(M)
microbenchmark(r_1 <- M_t %*% r, times=10, unit = 'ms')
```

```
## Unit: milliseconds
##              expr   min     lq    mean median     uq    max neval
##  r_1 <- M_t %*% r 0.163 0.1714 0.47328  0.173 0.1918 3.1293    10
```

```r
MM <- as.matrix(M_t)
microbenchmark(r_1 <- MM %*% r, times=10, unit = 'ms')
```

```
## Unit: milliseconds
##             expr     min      lq     mean   median      uq     max neval
##  r_1 <- MM %*% r 46.5308 46.6545 47.15746 47.01215 47.4353 48.3746    10
```


Así que podemos hacer nuestro algoritmo:


```r
r <- rep(1, 6012)/6012

for(i in 1:10){
  q <- 0.85 * (M_t %*% r)
  suma_q <- sum(q)
  r_nuevo <- q + (1 - suma_q) / 6012
  print(sum(abs(r_nuevo - r)))
  r <- r_nuevo
}
```

```
## [1] 0.4907346
## [1] 0.2554216
## [1] 0.1399171
## [1] 0.08249344
## [1] 0.05276466
## [1] 0.03433384
## [1] 0.02356974
## [1] 0.01614466
## [1] 0.01175786
## [1] 0.008488335
```



```r
nombres.pag <- read.table('../datos/data_hollings/nombres_paginas.txt')
nombres.pag$pagerank <- as.numeric(r)
arrange(nombres.pag, desc(pagerank))  |> head(10)
```

```
##     V1                                                              V2
## 1    2                                         http://www.hollins.edu/
## 2   37               http://www.hollins.edu/admissions/visit/visit.htm
## 3   38                     http://www.hollins.edu/about/about_tour.htm
## 4   61                         http://www.hollins.edu/htdig/index.html
## 5   52 http://www.hollins.edu/admissions/info-request/info-request.cfm
## 6   43               http://www.hollins.edu/admissions/apply/apply.htm
## 7  425 http://www.hollins.edu/academics/library/resources/web_linx.htm
## 8   27                http://www.hollins.edu/admissions/admissions.htm
## 9   28                  http://www.hollins.edu/academics/academics.htm
## 10  29                        http://www.hollins.edu/grad/coedgrad.htm
##       pagerank
## 1  0.020342191
## 2  0.009487376
## 3  0.008793044
## 4  0.008237781
## 5  0.008202176
## 6  0.007310231
## 7  0.006709038
## 8  0.006121904
## 9  0.005703552
## 10 0.004470490
```

```r
#write.csv(nombres.pag[,c('Label'),drop=FALSE], file='pagerank_hollings.csv', row.names=FALSE, col.names=FALSE)
ordenada <- arrange(nombres.pag, desc(pagerank))
```


Hacemos una búsqueda (simple, basada solamente en el nombre de la URL: esto normalmente
se haría con un índice invertido sobre el contenido):


```r
query <- 'admission'
ordenada |> filter(str_detect(V2, 'admission')) |> head()
```

```
##   V1                                                              V2
## 1 37               http://www.hollins.edu/admissions/visit/visit.htm
## 2 52 http://www.hollins.edu/admissions/info-request/info-request.cfm
## 3 43               http://www.hollins.edu/admissions/apply/apply.htm
## 4 27                http://www.hollins.edu/admissions/admissions.htm
## 5 81          http://www.hollins.edu/admissions/financial/finaid.htm
## 6 80         http://www.hollins.edu/admissions/ugradadm/ugradadm.htm
##      pagerank
## 1 0.009487376
## 2 0.008202176
## 3 0.007310231
## 4 0.006121904
## 5 0.003147287
## 6 0.002187616
```

```r
ordenada |> filter(str_detect(V2, 'admission')) |> tail()
```

```
##      V1
## 58 1290
## 59 1442
## 60 1028
## 61 1854
## 62 1590
## 63 1591
##                                                                          V2
## 58      http://www.hollins.edu/admissions/ugradadm/horizon/apply/apply1.cfm
## 59                       http://www.hollins.edu/admissions/apply/login2.cfm
## 60                   http://www.hollins.edu/admissions/scholarship/work.htm
## 61 http://www.hollins.edu/admissions/ugradadm/horizon/apply/app_review2.cfm
## 62  http://www.hollins.edu/admissions/ugradadm/horizon/apply/app_review.cfm
## 63     http://www.hollins.edu/admissions/ugradadm/horizon/apply/apply1a.cfm
##        pagerank
## 58 6.680171e-05
## 59 6.569320e-05
## 60 6.452762e-05
## 61 6.236121e-05
## 62 6.193540e-05
## 63 6.193540e-05
```

```r
query <- 'hollins'
ordenada |> filter(str_detect(V2, query)) |> head()
```

```
##   V1                                                              V2
## 1  2                                         http://www.hollins.edu/
## 2 37               http://www.hollins.edu/admissions/visit/visit.htm
## 3 38                     http://www.hollins.edu/about/about_tour.htm
## 4 61                         http://www.hollins.edu/htdig/index.html
## 5 52 http://www.hollins.edu/admissions/info-request/info-request.cfm
## 6 43               http://www.hollins.edu/admissions/apply/apply.htm
##      pagerank
## 1 0.020342191
## 2 0.009487376
## 3 0.008793044
## 4 0.008237781
## 5 0.008202176
## 6 0.007310231
```

```r
query <- 'student'
ordenada |> filter(str_detect(V2, query)) |> head(10)
```

```
##      V1
## 1    82
## 2    26
## 3  5955
## 4  6005
## 5    18
## 6  6004
## 7  5877
## 8  5956
## 9   467
## 10  468
##                                                                                                                                          V2
## 1                                                                          http://www.hollins.edu/admissions/ugradadm/students/students.htm
## 2                                                                                                 http://www.hollins.edu/students/index.htm
## 3                                                       http://www1.hollins.edu/Docs/CampusLife/StudentAct/studentorgs/Habitat/moreInfo.htm
## 4                                                       http://www1.hollins.edu/Docs/CampusLife/StudentAct/studentorgs/Habitat/whatWeDo.htm
## 5                                                           http://www1.hollins.edu/Docs/CampusLife/StudentAct/studentorgs/SGA/default.html
## 6                                                   http://www1.hollins.edu/Docs/CampusLife/StudentAct/studentorgs/Habitat/homeBuilding.htm
## 7                                                             http://www1.hollins.edu/Docs/CampusLife/StudentAct/studentorgs/hhrc/index.htm
## 8                                                           http://www1.hollins.edu/Docs/CampusLife/StudentAct/studentorgs/hhrc/contact.htm
## 9  http://www1.hollins.edu/Docs/CampusLife/StudentAct/studentorgs/SGA/forms/SGA%20Short%20Term%20Scholarship%20Application%20for%202004.doc
## 10 http://www1.hollins.edu/Docs/CampusLife/StudentAct/studentorgs/SGA/forms/SGA%20Short%20Term%20Scholarship%20Application%20for%202004.pdf
##        pagerank
## 1  0.0012740467
## 2  0.0007685934
## 3  0.0004847083
## 4  0.0004338779
## 5  0.0004295892
## 6  0.0003905306
## 7  0.0003813615
## 8  0.0003796379
## 9  0.0002657994
## 10 0.0002657994
```

