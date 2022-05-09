# Sistemas de recomendación y filtrado colaborativo


En esta sección discutiremos métodos que se pueden utilizar
para hacer recomendaciones de documentos, películas, artículos, etc.
a personas según sus intereses.

- **Problema**: predecir la respuesta de personas a estímulos a los que no han sido expuestos,
basados en respuesta a otros estímulos de esta y quizá otras personas similares.

Por ejemplo, si consideramos usuarios de Netflix: ¿qué tanto le puede gustar a X la película Y? Usuarios de Amazon: ¿qué tan probable es que compren Z artículo si se les ofrece?


## Enfoques de recomendación

Hay varios enfoques que podemos utilizar para atacar este problema:

- **Principalmente basados en contenido**:  En función de características de los estímulos, productos o películas (por ejemplo, género, actores, país de origen, año, etc.) intentamos predecir el gusto por el estímulo. En este enfoque, construimos variables derivadas del contenido de los artículos (por ejemplo: qué actores salen, año, etc. o en textos palabras que aparecen), e intentamos predecir el gusto a partir de esas características. 

Ejemplo: Si mu gustó *Twilight* entonces el sistema recomienda otros dramas+vampiros ("
por ejemplo "Entrevista con un vampiro").

- **Principalmente colaborativos**: utilizamos gustos o intereses de usuarios/artículos similares --- en el sentido de que les han gustado los mismos artículos/les gustaron a las mismas personas.

Ejemplo: Me gustó StarWars y Harry Potter, varios otros usuarios a los que también les gustaron estas dos películas también les gustó "Señor de los anillos", así que recomendamos "Señor de los Anillos". Entre estos métodos, veremos principalmente métodos basados en reducción de dimensionalidad o  **modelos de factores latentes**: encontrar factores latentes que describan usuarios y películas, y predecimos dependiendo de los niveles de factores latentes de personas y películas.


## Datos

Los datos utilizados para este tipo de sistemas son de dos
tipos:

- Ratings  *explícitos* dados por los usuarios (por ejemplo, Netflix mucho tiempo fue así: $1-5$ estrellas)

- Ratings *implícitos* que se derivan de la actividad de los usuarios (por ejemplo, vio la película completa, dio click en la descripción de un producto, etc.). 



### Ejemplo {-}

Consideramos evaluaciones en escala de gusto: por ejemplo $1-5$ estrellas, o $1$-me disgustó mucho, $5$-me gustó mucho, etc.

Podemos representar las evaluaciones como una matriz:


|   |SWars1 |SWars4 |SWars5 |HPotter1 |HPotter2 |Twilight |
|:--|:------|:------|:------|:--------|:--------|:--------|
|a  |3      |5      |5      |2        |-        |-        |
|b  |3      |-      |4      |-        |-        |-        |
|c  |-      |-      |-      |5        |4        |-        |
|d  |1      |-      |2      |-        |5        |4        |


Y lo que queremos hacer es predecir los valores faltantes de esta matriz, y seleccionar para cada usuario los artículos con predicción más alta, por ejemplo


|   |SWars1 |SWars4 |SWars5 |HPotter1 |HPotter2 |Twilight |
|:--|:------|:------|:------|:--------|:--------|:--------|
|a  |3      |5      |5      |2        |1.2      |3        |
|b  |3      |1.4    |4      |3        |3.3      |1.2      |
|c  |4.2    |2.8    |4.5    |5        |4        |3.1      |
|d  |1      |1.2    |2      |4.8      |5        |4        |

Podemos pensar en este problema como uno de **imputación de datos faltantes**. Las dificultades 
particulares de este problema son:

- Datos ralos: cada usuario sólo ha visto y calificado una proporción baja de películas, y hay películas con pocas vistas.
- Escalabilidad: el número de películas y usuarios es generalmente grande

Por estas razones, típicamente no es posible usar técnicas estadísticas de imputación de datos (como imputación estocástica basada en regresión)

- Usaremos mejor métodos más simples basados en similitud entre usuarios y películas y descomposición de matrices.

## Modelos de referencia y evaluación

Vamos a comenzar considerando modelos muy simples. El primero que se nos puede ocurrir es uno
de homogeneidad de gustos: para una persona $i$, nuestra predicción de su gusto por la película
$j$ es simplemente la media de la película $j$ sobre todos los usuarios que la han visto. 

Este sería un buen modelo si los gustos fueran muy parecidos sobre todos los usuarios. Esta sería una recomendación de "artículos populares".

Introducimos la siguente notación:

- $x_{ij}$ es la evaluación del usuario $i$ de la película $j$. Obsérvese que muchos de estos valores no son observados (no tenemos información de varias $x_{ij}$).
- $\hat{x}_{ij}$ es la predicción que hacemos de gusto del usuario $i$ por la película $j$


En nuestro primer modelo simple, nuestra predicción es simplemente
$$\hat{x}_{ij} = \hat{b}_j$$
donde 
$$\hat{b_j} = \frac{1}{N_j}\sum_{s} x_{sj},$$
y este promedio es sobre los $N_j$ usuarios que vieron (y calificaron) la película $j$.

¿Cómo evaluamos nuestras predicciones?

### Evaluación de predicciones

Usamos muestras de entrenamiento y validación. Como en el concurso de Netflix,
utilizaremos la raíz del error cuadrático medio:

$$RECM =\left ( \frac{1}{T} \sum_{(i,j) \, observada} (x_{ij}-\hat{x}_{ij})^2 \right)^{\frac{1}{2}}$$

aunque también podríamos utilizar la desviación absoluta media:

$$DAM =\frac{1}{T} \sum_{(i,j) \, observada} |x_{ij}-\hat{x}_{ij}|$$

- Nótese que estas dos cantidades se evaluán sólo sobre los pares $(i,j)$ para los
que tengamos una observación $x_{ij}$.

**Observaciones**:

- Generalmente evaluamos sobre un conjunto de validación separado del conjunto
de entrenamiento.

- Escogemos una muestra de películas, una muestra de usuarios, y ponemos
en validación el conjunto de calificaciones de esos usuarios para esas películas. 

- Para hacer un conjunto de prueba, idealmente los datos deben ser de películas
que hayan sido observadas por los usuarios en el futuro (después del periodo de los
datos de entrenamiento).

- Nótese que no seleccionamos *todas* las evaluaciones de un usuario, ni *todas* las
evaluaciones de una película. Con estas estrategias, veríamos qué pasa con nuestro
modelo cuando tenemos una película que no se ha visto o un usuario nuevo.
Lo que queremos ententer es cómo se desempeña nuestro sistema
cuando tenemos cierta información de usuarios y de películas.


### Ejemplo: datos de Netflix {-}


Los datos del concurso de Netflix originalmente vienen en archivos de texto, un archivo por película.

The movie rating files contain over $100$ million ratings from $480$ thousand
randomly-chosen, anonymous Netflix customers over $17$ thousand movie titles.  The
data were collected between October, $1998$ and December, $2005$ and reflect the
distribution of all ratings received during this period.  The ratings are on a
scale from $1$ to $5$ (integral) stars. To protect customer privacy, each customer
id has been replaced with a randomly-assigned id.  The date of each rating and
the title and year of release for each movie id are also provided.

The file "training_set.tar" is a tar of a directory containing $17770$ files, one
per movie.  The first line of each file contains the movie id followed by a
colon.  Each subsequent line in the file corresponds to a rating from a customer
and its date in the following format:

CustomerID,Rating,Date

- MovieIDs range from $1$ to $17770$ sequentially.
- CustomerIDs range from $1$ to $2649429$, with gaps. There are $480189$ users.
- Ratings are on a five star (integral) scale from $1$ to $5$.
- Dates have the format YYYY-MM-DD.

---

En primer lugar haremos un análisis exploratorio de los datos para entender algunas
de sus características, ajustamos el modelo simple de gustos homogéneos (la predicción es el
promedio de calificaciones de cada película), y lo evaluamos.

Comenzamos por cargar los datos:


```r
library(tidyverse)
theme_set(theme_minimal())
cb_palette <- c("#000000", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7")
```



```r
# url <- "https://s3.amazonaws.com/ma-netflix/dat_muestra_nflix.csv"
pelis_nombres <- read_csv('../datos/netflix/movies_title_fix.csv', col_names = FALSE, na = c("", "NA", "NULL"))
```

```
## Rows: 17770 Columns: 3
```

```
## ── Column specification ────────────────────────────────────────────────────────
## Delimiter: ","
## chr (1): X3
## dbl (2): X1, X2
```

```
## 
## ℹ Use `spec()` to retrieve the full column specification for this data.
## ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.
```

```r
names(pelis_nombres) <- c('peli_id','año','nombre')
dat_netflix <- read_csv( "../datos/netflix/dat_muestra_nflix.csv", progress = FALSE) |> 
    select(-usuario_id_orig) |> 
    mutate(usuario_id = as.integer(as.factor(usuario_id)))
```

```
## Rows: 20968941 Columns: 5
```

```
## ── Column specification ────────────────────────────────────────────────────────
## Delimiter: ","
## dbl  (4): peli_id, usuario_id_orig, calif, usuario_id
## date (1): fecha
```

```
## 
## ℹ Use `spec()` to retrieve the full column specification for this data.
## ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.
```

```r
head(dat_netflix)
```

```
## # A tibble: 6 × 4
##   peli_id calif fecha      usuario_id
##     <dbl> <dbl> <date>          <int>
## 1       1     3 2004-04-14          1
## 2       1     3 2004-12-28          2
## 3       1     4 2004-04-06          3
## 4       1     4 2004-03-07          4
## 5       1     4 2004-03-29          5
## 6       1     2 2004-07-11          6
```

```r
dat_netflix |> tally()
```

```
## # A tibble: 1 × 1
##          n
##      <int>
## 1 20968941
```


Y ahora calculamos las medias de cada película. 


```r
medias_pelis <- dat_netflix |> group_by(peli_id) |> 
    summarise(media_peli = mean(calif), num_calif_peli = n()) 
medias_pelis <- left_join(medias_pelis, pelis_nombres)
```

```
## Joining, by = "peli_id"
```


```r
arrange(medias_pelis, desc(media_peli)) |> 
  top_n(200, media_peli) |> 
  mutate(media_peli = round(media_peli, 2)) |>
  DT::datatable()
```

```{=html}
<div id="htmlwidget-400feeeb8cae8180668c" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-400feeeb8cae8180668c">{"x":{"filter":"none","vertical":false,"data":[["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","32","33","34","35","36","37","38","39","40","41","42","43","44","45","46","47","48","49","50","51","52","53","54","55","56","57","58","59","60","61","62","63","64","65","66","67","68","69","70","71","72","73","74","75","76","77","78","79","80","81","82","83","84","85","86","87","88","89","90","91","92","93","94","95","96","97","98","99","100","101","102","103","104","105","106","107","108","109","110","111","112","113","114","115","116","117","118","119","120","121","122","123","124","125","126","127","128","129","130","131","132","133","134","135","136","137","138","139","140","141","142","143","144","145","146","147","148","149","150","151","152","153","154","155","156","157","158","159","160","161","162","163","164","165","166","167","168","169","170","171","172","173","174","175","176","177","178","179","180","181","182","183","184","185","186","187","188","189","190","191","192","193","194","195","196","197","198","199","200"],[14791,8964,6522,4614,14961,7230,15538,7057,9864,3456,16875,1587,5018,4238,12398,13504,14550,13,2608,10464,1418,7833,2102,3033,5103,5582,11662,14240,2568,16587,15296,12834,2700,7664,15437,17307,10042,12293,16265,9063,11216,3444,2019,9436,17085,1499,8468,17219,8116,2598,1476,7569,1947,4427,12681,16302,15861,15104,13556,9628,14302,8535,11521,12891,2117,10640,7815,8447,12870,10080,2114,5760,7110,10644,12530,2452,1072,1915,14729,3962,16147,13665,7742,16711,3046,2162,17480,10643,4348,11641,3290,7751,2172,8226,9040,8038,3067,16006,10598,724,1357,5292,4294,14031,15557,6974,5738,13673,13205,5258,15609,4789,5092,2591,3965,2057,15500,4877,12755,7749,4353,14648,5530,15014,7539,1495,4098,2321,8355,1256,3247,9644,14621,5837,12731,9909,7445,16954,6007,3928,5161,9979,10011,10251,10973,12184,4691,7302,4306,710,3523,7430,7639,9483,14806,2803,2862,7396,2575,14537,12035,15768,8580,14615,2548,11026,13663,5714,8934,4978,16377,10947,12937,7193,11191,5519,11283,12107,13478,1020,11607,7695,7669,1409,12125,10778,11202,2782,8664,3593,10825,6428,14283,12219,11705,17157,10519,4207,11126,270],[4.88,4.83,4.76,4.75,4.72,4.71,4.7,4.69,4.68,4.68,4.67,4.65,4.63,4.62,4.62,4.6,4.6,4.59,4.59,4.58,4.57,4.56,4.56,4.56,4.55,4.55,4.55,4.54,4.54,4.53,4.52,4.52,4.51,4.51,4.51,4.5,4.5,4.5,4.5,4.5,4.5,4.5,4.49,4.49,4.48,4.48,4.48,4.48,4.48,4.48,4.47,4.47,4.47,4.47,4.47,4.46,4.46,4.46,4.46,4.46,4.46,4.46,4.46,4.46,4.45,4.45,4.45,4.45,4.45,4.45,4.45,4.45,4.44,4.43,4.43,4.43,4.43,4.42,4.42,4.42,4.42,4.42,4.41,4.41,4.41,4.41,4.41,4.41,4.4,4.4,4.4,4.4,4.4,4.39,4.39,4.39,4.38,4.38,4.38,4.38,4.38,4.38,4.38,4.37,4.37,4.37,4.37,4.37,4.37,4.37,4.36,4.36,4.36,4.36,4.36,4.36,4.36,4.36,4.36,4.35,4.35,4.35,4.35,4.35,4.35,4.34,4.34,4.34,4.34,4.34,4.34,4.34,4.34,4.34,4.34,4.34,4.34,4.34,4.34,4.34,4.33,4.33,4.33,4.33,4.33,4.33,4.33,4.33,4.33,4.33,4.33,4.33,4.33,4.32,4.32,4.32,4.32,4.31,4.31,4.31,4.31,4.31,4.31,4.31,4.31,4.31,4.31,4.31,4.31,4.31,4.31,4.3,4.3,4.3,4.3,4.3,4.3,4.3,4.3,4.3,4.3,4.3,4.3,4.3,4.3,4.3,4.29,4.29,4.29,4.29,4.29,4.29,4.29,4.29,4.29,4.29,4.29,4.29,4.29,4.29],[17,6,29,4,15260,15191,329,15528,364,1502,6,34,146,371,245,345,29112,27,39,19,166,1327,1700,45,3564,19250,4242,27918,398,3835,7789,4475,47,2001,751,2477,24745,22253,17858,30,16,2111,443,86,4894,195,2655,1887,7219,21,2384,824,1003,1359,15,4840,2852,104,1801,18517,8414,3863,31611,3637,22,11,559,6437,21287,5197,2191,7937,1368,1058,5885,31146,84,373,656,29391,9062,43,3160,6934,3264,3576,1651,1793,97,502,14953,1703,4700,2138,31,1654,26,2280,3802,221,1364,2988,8,1950,1942,22561,2549,10638,679,1265,2358,1481,2381,36,381,1991,1309,2278,42,1478,2481,2239,1558,1313,182,3490,1371,61,137,2334,123,1500,26868,3821,890,3249,822,30052,3952,1503,12,9,12,48,39,6969,874,666,31436,49,1913,7104,470,62,1536,4158,26769,108,178,70,691,163,1915,32,1818,476,2876,331,13,1674,37800,27862,2216,18557,2788,2309,38071,10,10,4285,19330,2230,1524,1083,899,2242,136,28364,780,1053,379,13330,2165,48,151,27276,31,1485,1248,7504],[2003,2003,2001,1964,2003,2001,2004,2002,2004,2004,2005,1962,2001,2000,2004,2004,1994,2003,2003,1995,2002,2004,1994,2005,1993,1980,2004,2003,2004,1992,2001,2001,2005,2000,2002,2003,1981,1972,1977,2004,1991,2004,2004,2002,2002,2000,2002,1991,2002,2005,2004,2004,2002,2001,1996,1999,2001,1987,1999,1983,2000,1990,2002,2003,2004,1976,2003,2001,1993,2001,2002,2001,2004,2002,2004,2001,2000,2000,2004,2003,1999,2002,2003,2003,1990,2000,2003,1992,2002,1994,1974,1985,1991,2000,1999,1950,2004,1989,2004,1992,2003,2002,2004,2002,1999,1995,2003,1995,2004,1990,2001,2001,1997,2003,1992,2001,2001,2004,1995,2005,2002,2003,2000,2003,1991,2001,2002,2004,2005,1994,2005,2002,2001,1999,2001,2002,2004,1989,2003,2004,2005,1975,2005,2005,2005,2002,2002,2001,1999,1993,1992,2001,2004,1992,2001,1995,1991,1969,2004,1989,2002,2000,1999,2001,2000,2002,2000,1974,2003,2000,1999,2004,1999,1987,1999,1999,1994,2001,1973,1989,2005,1999,2004,2003,2001,2001,1999,1995,2001,1988,1993,1962,1994,2000,1997,1998,2003,1980,2000,2001],["Trailer Park Boys: Season 3","Trailer Park Boys: Season 4","Trailer Park Boys: Seasons 1 &amp; 2","Blood and Black Lace","Lord of the Rings: The Return of the King: Extended Edition","The Lord of the Rings: The Fellowship of the Ring: Extended Edition","Fullmetal Alchemist","Lord of the Rings: The Two Towers: Extended Edition","Battlestar Galactica: Season 1","Lost: Season 1","Ah! My Goddess","Harakiri","Fruits Basket","Inu-Yasha","Veronica Mars: Season 1","House M.D.: Season 1","The Shawshank Redemption: Special Edition","Lord of the Rings: The Return of the King: Extended Edition: Bonus Material","WWE: Mick Foley's Greatest Hits and Misses","Tenchi Muyo! Ryo Ohki","Inu-Yasha: The Movie 3: Swords of an Honorable Ruler","Arrested Development: Season 2","The Simpsons: Season 6","Ghost in the Shell: Stand Alone Complex: 2nd Gig","The Simpsons: Season 5","Star Wars: Episode V: The Empire Strikes Back","The Sopranos: Season 5","Lord of the Rings: The Return of the King","Stargate SG-1: Season 8","The Simpsons: Season 4","Band of Brothers","Family Guy: Vol. 2: Season 3","ECW: One Night Stand","Gladiator: Extended Edition","South Park: Season 6","CSI: Season 4","Raiders of the Lost Ark","The Godfather","Star Wars: Episode IV: A New Hope","Shura no Toki","Gundam 0083: Stardust Memory","Family Guy: Freakin' Sweet Collection","Samurai Champloo","Full Metal Panic FUMOFFU","24: Season 2","FLCL","CSI: Season 3","Seinfeld: Season 3","The Sopranos: Season 4","Baby Einstein: On the Go: Riding Sailing and Soaring","Six Feet Under: Season 4","Dead Like Me: Season 2","Gilmore Girls: Season 3","The West Wing: Season 3","Kodocha","Family Guy: Vol. 1: Seasons 1-2","CSI: Season 2","Anne of Green Gables: The Sequel","The West Wing: Season 2","Star Wars: Episode VI: Return of the Jedi","The Sopranos: Season 2","The Simpsons: Season 2","Lord of the Rings: The Two Towers","24: Season 3","Case Closed: Season 5","The Duchess of Duke Street: Series 1","Gilmore Girls: Season 4","24: Season 1","Schindler's List","Six Feet Under: Season 2","Firefly","The Sopranos: Season 3","The Shield: Season 3","The West Wing: Season 4","Sex and the City: Season 6: Part 2","Lord of the Rings: The Fellowship of the Ring","As Time Goes By: Series 8","Law &amp; Order: Special Victims Unit: The Second Year","Smallville: Season 4","Finding Nemo (Widescreen)","The Sopranos: Season 1","As Time Goes By: Series 9","Six Feet Under: Season 3","Sex and the City: Season 6: Part 1","The Simpsons: Treehouse of Horror","CSI: Season 1","The Shield: Season 2","Seinfeld: Season 4","The Twelve Kingdoms","My So-Called Life","The Godfather Part II","Anne of Green Gables","The Simpsons: Season 3","Buffy the Vampire Slayer: Season 5","The Sixth Sense: Bonus Material","Cinderella: Special Edition","Teen Titans: Season 2","Seinfeld: Seasons 1 &amp; 2","Chappelle's Show: Season 2","Yu Yu Hakusho","Stargate SG-1: Season 7","Alias: Season 2","Ghost Hunters: Season 1","Buffy the Vampire Slayer: Season 7","Futurama: Vol. 3","The Usual Suspects","Alias: Season 3","Toy Story","Rescue Me: Season 1","Ken Burns' Civil War","South Park: Season 5","Stargate SG-1: Season 5","Buffy the Vampire Slayer: Season 2","Maburaho","Red Dwarf: Series 5","Buffy the Vampire Slayer: Season 6","Gilmore Girls: Season 2","Simpsons Gone Wild","WWE: The Monday Night War","Curb Your Enthusiasm: Season 4","Curb Your Enthusiasm: Season 3","Finding Nemo (Full-screen)","Stargate SG-1: Season 4","Angel: Season 5","The Kids in the Hall: Season 3","Alias: Season 1","Angel: Season 4","Get Backers","UFC 52: Ultimate Fighting Championship: Randy Couture vs. Chuck Liddell","The Best of Friends: Vol. 4","The Looney Tunes Golden Collection: Vol. 3","Stargate SG-1: Season 6","Shrek (Full-screen)","Friends: Season 7","Farscape: Season 3","Friends: Season 9","Monk: Season 3","Indiana Jones and the Last Crusade","Arrested Development: Season 1","Nip/Tuck: Season 2","Pride FC: Body Blow","The Hiding Place","Lamb of God: Killadelphia","Samurai 7","WWE: Vengeance: Hell in a Cell","Sex and the City: Season 5","Farscape: Season 4","The Blue Planet: Seas of Life: Seasonal Seas - Coral Seas","The Sixth Sense","Inspector Morse 9: The Last Enemy","Star Trek: The Next Generation: Season 6","Six Feet Under: Season 1","Star Wars Trilogy: Bonus Material","Inspector Morse 8: Ghost in the Machine","Angel: Season 3","Pride and Prejudice","The Silence of the Lambs","The Twilight Zone: Vol. 43","R.O.D. the TV Series","Garfield and Friends: Vol. 3","Oz: Season 5","The Simpsons: Christmas 2","Futurama: Vol. 4","Abraham and Mary Lincoln: A House Divided: American Experience","Gilmore Girls: Season 1","Inu-Yasha: The Movie 2: The Castle Beyond the Looking Glass","South Park: Season 4","Upstairs Downstairs: Season 4","Johnny Cash: Hurt: A Film by Mark Romanek","Freaks &amp; Geeks: The Complete Series","The Green Mile","The Incredibles","Buffy the Vampire Slayer: Season 4","The Princess Bride","South Park: Season 3","The West Wing: Season 1","Forrest Gump","The Merchants of Cool: Frontline","Ivan Vasilievich: Back to the Future","The Simpsons: Season 1","Hotel Rwanda","Futurama: Vol. 2","Desperate Housewives: Season 1","The O.C.: Season 1","The Blue Planet: Seas of Life: Open Ocean - The Deep","Scrubs: Season 1","Initial D","Braveheart","The Blue Planet: Seas of Life: Ocean World - Frozen Seas","My Neighbor Totoro","Red Dwarf: Series 6","To Kill a Mockingbird","The Best of Friends: Vol. 3","Dragon Ball Z: Vegeta Saga 1","VeggieTales: A Snoodles Tale","Saving Private Ryan","The Howlin' Wolf Story","The Blues Brothers: Extended Cut","Oz: Season 4","Sex and the City: Season 4"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>peli_id<\/th>\n      <th>media_peli<\/th>\n      <th>num_calif_peli<\/th>\n      <th>año<\/th>\n      <th>nombre<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,3,4]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script>
```

Nótese que varias de las películas con mejor promedio tienen muy pocas evaluaciones. Podemos
examinar más detalladamente graficando número de evaluaciones vs promedio:



```r
ggplot(medias_pelis, aes(x=num_calif_peli, y=media_peli)) + 
  geom_point(alpha = 0.1) + xlab("Número de calificaciones") + 
  ylab("Promedio de calificaciones") 
```

<img src="04-recomendacion_files/figure-html/unnamed-chunk-6-1.png" width="672" />


Y vemos que hay más variabilidad en los promedios cuando hay menos evaluaciones, como
es de esperarse. ¿Puedes ver algún problema que tendremos que enfrentar con el modelo simple? 


Si filtramos por número de calificaciones (al menos $500$ por ejemplo), 
estas son las películas mejor calificadas (la mayoría conocidas y populares):


```r
arrange(medias_pelis, desc(media_peli)) |> 
  filter(num_calif_peli > 500) |>
  top_n(200, media_peli) |> 
  mutate(media_peli = round(media_peli, 2)) |>
  DT::datatable()
```

```{=html}
<div id="htmlwidget-3f82b3d507efbc1147cd" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-3f82b3d507efbc1147cd">{"x":{"filter":"none","vertical":false,"data":[["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","32","33","34","35","36","37","38","39","40","41","42","43","44","45","46","47","48","49","50","51","52","53","54","55","56","57","58","59","60","61","62","63","64","65","66","67","68","69","70","71","72","73","74","75","76","77","78","79","80","81","82","83","84","85","86","87","88","89","90","91","92","93","94","95","96","97","98","99","100","101","102","103","104","105","106","107","108","109","110","111","112","113","114","115","116","117","118","119","120","121","122","123","124","125","126","127","128","129","130","131","132","133","134","135","136","137","138","139","140","141","142","143","144","145","146","147","148","149","150","151","152","153","154","155","156","157","158","159","160","161","162","163","164","165","166","167","168","169","170","171","172","173","174","175","176","177","178","179","180","181","182","183","184","185","186","187","188","189","190","191","192","193","194","195","196","197","198","199","200"],[14961,7230,7057,3456,14550,7833,2102,5103,5582,11662,14240,16587,15296,12834,7664,15437,17307,10042,12293,16265,3444,17085,8468,17219,8116,1476,7569,1947,4427,16302,15861,13556,9628,14302,8535,11521,12891,7815,8447,12870,10080,2114,5760,7110,10644,12530,2452,14729,3962,16147,7742,16711,3046,2162,17480,10643,11641,3290,7751,2172,8226,8038,16006,10598,1357,5292,14031,15557,6974,5738,13673,13205,5258,15609,4789,5092,2057,15500,4877,7749,4353,14648,5530,15014,1495,4098,1256,9644,14621,5837,12731,9909,7445,16954,6007,3928,12184,4691,7302,4306,3523,7430,14806,2803,2862,12035,8580,2548,13663,4978,16377,10947,12937,7193,11191,5519,11283,1020,11607,7695,7669,1409,12125,10778,2782,8664,3593,6428,14283,17157,4207,11126,270,5326,5732,4115,14911,1441,4383,316,5549,11089,7605,7393,17682,7303,2942,774,16022,3958,15777,10072,13669,17165,15773,17687,10061,8327,752,14533,11925,2566,15333,11050,15836,12384,2861,7158,12811,2040,16615,2195,7735,10418,12999,6355,1795,5297,6739,13123,3864,12100,11164,8438,14571,12956,13468,5886,14709,15183,9326,16394,6142,14742,14691,15534,16278,7235,7683,12026],[4.72,4.71,4.69,4.68,4.6,4.56,4.56,4.55,4.55,4.55,4.54,4.53,4.52,4.52,4.51,4.51,4.5,4.5,4.5,4.5,4.5,4.48,4.48,4.48,4.48,4.47,4.47,4.47,4.47,4.46,4.46,4.46,4.46,4.46,4.46,4.46,4.46,4.45,4.45,4.45,4.45,4.45,4.45,4.44,4.43,4.43,4.43,4.42,4.42,4.42,4.41,4.41,4.41,4.41,4.41,4.41,4.4,4.4,4.4,4.4,4.39,4.39,4.38,4.38,4.38,4.38,4.37,4.37,4.37,4.37,4.37,4.37,4.37,4.36,4.36,4.36,4.36,4.36,4.36,4.35,4.35,4.35,4.35,4.35,4.34,4.34,4.34,4.34,4.34,4.34,4.34,4.34,4.34,4.34,4.34,4.34,4.33,4.33,4.33,4.33,4.33,4.33,4.32,4.32,4.32,4.31,4.31,4.31,4.31,4.31,4.31,4.3,4.3,4.3,4.3,4.3,4.3,4.3,4.3,4.3,4.3,4.3,4.3,4.3,4.29,4.29,4.29,4.29,4.29,4.29,4.29,4.29,4.29,4.28,4.28,4.28,4.28,4.28,4.28,4.28,4.28,4.28,4.28,4.28,4.28,4.28,4.28,4.28,4.28,4.28,4.28,4.27,4.27,4.27,4.27,4.27,4.27,4.26,4.26,4.26,4.26,4.26,4.26,4.26,4.26,4.26,4.26,4.26,4.25,4.25,4.25,4.25,4.25,4.24,4.24,4.24,4.24,4.24,4.24,4.24,4.24,4.24,4.23,4.23,4.23,4.23,4.23,4.23,4.23,4.23,4.23,4.22,4.22,4.22,4.22,4.22,4.22,4.21,4.21,4.21],[15260,15191,15528,1502,29112,1327,1700,3564,19250,4242,27918,3835,7789,4475,2001,751,2477,24745,22253,17858,2111,4894,2655,1887,7219,2384,824,1003,1359,4840,2852,1801,18517,8414,3863,31611,3637,559,6437,21287,5197,2191,7937,1368,1058,5885,31146,656,29391,9062,3160,6934,3264,3576,1651,1793,502,14953,1703,4700,2138,1654,2280,3802,1364,2988,1950,1942,22561,2549,10638,679,1265,2358,1481,2381,1991,1309,2278,1478,2481,2239,1558,1313,3490,1371,2334,1500,26868,3821,890,3249,822,30052,3952,1503,6969,874,666,31436,1913,7104,1536,4158,26769,691,1915,1818,2876,1674,37800,27862,2216,18557,2788,2309,38071,4285,19330,2230,1524,1083,899,2242,28364,780,1053,13330,2165,27276,1485,1248,7504,1802,18898,873,2006,1603,837,517,2970,27089,1191,535,2447,1017,3975,514,1338,1144,3726,612,572,1428,998,1500,1370,18232,1785,3933,1020,1611,774,1091,900,1206,710,3792,2490,1878,625,856,559,3328,2389,1686,1076,1239,12076,1183,11547,598,8148,4386,930,1775,664,1830,1712,1278,1533,508,1101,2131,29401,548,2570,1180,4049,571],[2003,2001,2002,2004,1994,2004,1994,1993,1980,2004,2003,1992,2001,2001,2000,2002,2003,1981,1972,1977,2004,2002,2002,1991,2002,2004,2004,2002,2001,1999,2001,1999,1983,2000,1990,2002,2003,2003,2001,1993,2001,2002,2001,2004,2002,2004,2001,2004,2003,1999,2003,2003,1990,2000,2003,1992,1994,1974,1985,1991,2000,1950,1989,2004,2003,2002,2002,1999,1995,2003,1995,2004,1990,2001,2001,1997,2001,2001,2004,2005,2002,2003,2000,2003,2001,2002,1994,2002,2001,1999,2001,2002,2004,1989,2003,2004,2002,2002,2001,1999,1992,2001,2001,1995,1991,2002,1999,2000,2000,2000,1999,2004,1999,1987,1999,1999,1994,1989,2005,1999,2004,2003,2001,2001,1995,2001,1988,1962,1994,1998,1980,2000,2001,1990,1990,1999,2002,1998,2004,1999,2001,2001,2004,1993,1998,2002,1999,2003,2003,2003,2001,2004,1988,2004,2003,1997,2003,1975,1993,2002,2003,1999,1999,1977,1979,2001,1996,1997,2000,1991,2001,2004,1997,1997,2003,2002,1978,2000,1954,1976,2005,1992,2000,1998,1999,2000,1992,2000,1988,1975,2003,1995,2003,2000,1999,2001,2004,2003,1988,1996],["Lord of the Rings: The Return of the King: Extended Edition","The Lord of the Rings: The Fellowship of the Ring: Extended Edition","Lord of the Rings: The Two Towers: Extended Edition","Lost: Season 1","The Shawshank Redemption: Special Edition","Arrested Development: Season 2","The Simpsons: Season 6","The Simpsons: Season 5","Star Wars: Episode V: The Empire Strikes Back","The Sopranos: Season 5","Lord of the Rings: The Return of the King","The Simpsons: Season 4","Band of Brothers","Family Guy: Vol. 2: Season 3","Gladiator: Extended Edition","South Park: Season 6","CSI: Season 4","Raiders of the Lost Ark","The Godfather","Star Wars: Episode IV: A New Hope","Family Guy: Freakin' Sweet Collection","24: Season 2","CSI: Season 3","Seinfeld: Season 3","The Sopranos: Season 4","Six Feet Under: Season 4","Dead Like Me: Season 2","Gilmore Girls: Season 3","The West Wing: Season 3","Family Guy: Vol. 1: Seasons 1-2","CSI: Season 2","The West Wing: Season 2","Star Wars: Episode VI: Return of the Jedi","The Sopranos: Season 2","The Simpsons: Season 2","Lord of the Rings: The Two Towers","24: Season 3","Gilmore Girls: Season 4","24: Season 1","Schindler's List","Six Feet Under: Season 2","Firefly","The Sopranos: Season 3","The Shield: Season 3","The West Wing: Season 4","Sex and the City: Season 6: Part 2","Lord of the Rings: The Fellowship of the Ring","Smallville: Season 4","Finding Nemo (Widescreen)","The Sopranos: Season 1","Six Feet Under: Season 3","Sex and the City: Season 6: Part 1","The Simpsons: Treehouse of Horror","CSI: Season 1","The Shield: Season 2","Seinfeld: Season 4","My So-Called Life","The Godfather Part II","Anne of Green Gables","The Simpsons: Season 3","Buffy the Vampire Slayer: Season 5","Cinderella: Special Edition","Seinfeld: Seasons 1 &amp; 2","Chappelle's Show: Season 2","Stargate SG-1: Season 7","Alias: Season 2","Buffy the Vampire Slayer: Season 7","Futurama: Vol. 3","The Usual Suspects","Alias: Season 3","Toy Story","Rescue Me: Season 1","Ken Burns' Civil War","South Park: Season 5","Stargate SG-1: Season 5","Buffy the Vampire Slayer: Season 2","Buffy the Vampire Slayer: Season 6","Gilmore Girls: Season 2","Simpsons Gone Wild","Curb Your Enthusiasm: Season 4","Curb Your Enthusiasm: Season 3","Finding Nemo (Full-screen)","Stargate SG-1: Season 4","Angel: Season 5","Alias: Season 1","Angel: Season 4","The Best of Friends: Vol. 4","Stargate SG-1: Season 6","Shrek (Full-screen)","Friends: Season 7","Farscape: Season 3","Friends: Season 9","Monk: Season 3","Indiana Jones and the Last Crusade","Arrested Development: Season 1","Nip/Tuck: Season 2","Sex and the City: Season 5","Farscape: Season 4","The Blue Planet: Seas of Life: Seasonal Seas - Coral Seas","The Sixth Sense","Star Trek: The Next Generation: Season 6","Six Feet Under: Season 1","Angel: Season 3","Pride and Prejudice","The Silence of the Lambs","Oz: Season 5","Futurama: Vol. 4","Gilmore Girls: Season 1","South Park: Season 4","Freaks &amp; Geeks: The Complete Series","The Green Mile","The Incredibles","Buffy the Vampire Slayer: Season 4","The Princess Bride","South Park: Season 3","The West Wing: Season 1","Forrest Gump","The Simpsons: Season 1","Hotel Rwanda","Futurama: Vol. 2","Desperate Housewives: Season 1","The O.C.: Season 1","The Blue Planet: Seas of Life: Open Ocean - The Deep","Scrubs: Season 1","Braveheart","The Blue Planet: Seas of Life: Ocean World - Frozen Seas","My Neighbor Totoro","To Kill a Mockingbird","The Best of Friends: Vol. 3","Saving Private Ryan","The Blues Brothers: Extended Cut","Oz: Season 4","Sex and the City: Season 4","Star Trek: The Next Generation: Season 4","GoodFellas: Special Edition","The Simpsons: Bart Wars","The Shield: Season 1","Stargate SG-1: Season 2","Farscape: The Peacekeeper Wars","Futurama: Monster Robot Maniac Fun Collection","Curb Your Enthusiasm: Season 2","Monsters Inc.","Queer as Folk: Season 4","Prime Suspect 3","Buffy the Vampire Slayer: Season 3","Coupling: Season 3","Friends: Season 6","Foyle's War: Set 2","Battlestar Galactica: The Miniseries","Monk: Season 2","Friends: Season 8","Prime Suspect 6","Red Dwarf: Series 4","The Daily Show with Jon Stewart: Indecision 2004","Aqua Teen Hunger Force: Vol. 3","Oz: Season 3","Smallville: Season 3","One Flew Over the Cuckoo's Nest","Star Trek: The Next Generation: Season 7","The Office: Series 2","The Wire: Season 2","Stargate SG-1: Season 3","Samurai X: Trust and Betrayal Director's Cut","MASH: Season 6","MASH: Season 8","Coupling: Season 2","Babylon 5: Season 4","The Best of Friends: Season 4","The X-Files: Season 1","Star Trek: The Next Generation: Season 5","Shrek (Widescreen)","The Looney Tunes Golden Collection: Vol. 2","Rurouni Kenshin","South Park: Season 1","Nip/Tuck: Season 1","Smallville: Season 2","MASH: Season 7","Aqua Teen Hunger Force: Vol. 2","Rear Window","MASH: Season 5","Batman Begins","Prime Suspect 2","Sex and the City: Season 3","Friends: Season 5","Toy Story 2","Angel: Season 2","Law &amp; Order: Season 3","The X-Files: Season 3","Star Trek: The Next Generation: Season 2","MASH: Season 4","Queer as Folk: Season 3","Prime Suspect 4","Law &amp; Order: Special Victims Unit: The Fifth Year","The X-Files: Season 2","The Matrix","Inu-Yasha: The Movie: Affections Touching Across Time","Something the Lord Made","Carnivale: Season 1","Cinema Paradiso: Director's Cut","ER: Season 3"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>peli_id<\/th>\n      <th>media_peli<\/th>\n      <th>num_calif_peli<\/th>\n      <th>año<\/th>\n      <th>nombre<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":[1,2,3,4]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script>
```

Ahora seleccionamos nuestra muestra de entrenamiento y de validación. Seleccionamos una
muestra de usuarios y de películas:


```r
set.seed(28882)
usuarios <- dat_netflix |> select(usuario_id) |> distinct()
valida_usuarios <- usuarios |> sample_frac(0.2) 
peliculas <-  dat_netflix |> select(peli_id) |> distinct()
valida_pelis <- peliculas |> sample_frac(0.2)
```

Y separamos calificaciones de entrenamiento y validación:


```r
dat_valida <- dat_netflix |> 
  semi_join(valida_usuarios) |> 
  semi_join(valida_pelis) 
```

```
## Joining, by = "usuario_id"
```

```
## Joining, by = "peli_id"
```

```r
dat_entrena <- dat_netflix |> 
  anti_join(dat_valida)
```

```
## Joining, by = c("peli_id", "calif", "fecha", "usuario_id")
```

```r
n_valida <- dat_valida |> tally() |> pull(n)
n_entrena <- dat_entrena |> tally() |> pull(n)
sprintf("Entrenamiento: %1d, Validación: %2d, Total: %3d", n_entrena, 
        n_valida, n_entrena + n_valida)
```

```
## [1] "Entrenamiento: 20191991, Validación: 776950, Total: 20968941"
```

Ahora construimos predicciones con el modelo simple de arriba y evaluamos con validación:


```r
medias_pred <- dat_entrena |> group_by(peli_id) |>
  summarise(media_pred = mean(calif)) 
media_total_e <- dat_entrena |> ungroup() |> summarise(media = mean(calif)) |> pull(media)
dat_valida_pred <- dat_valida |> left_join(medias_pred |> collect()) 
head(dat_valida_pred)
```

```
## # A tibble: 6 × 5
##   peli_id calif fecha      usuario_id media_pred
##     <dbl> <dbl> <date>          <int>      <dbl>
## 1       2     5 2005-07-18        116       3.64
## 2       2     4 2005-06-07        126       3.64
## 3       2     4 2005-07-30        129       3.64
## 4       2     1 2005-09-07        131       3.64
## 5       2     1 2005-02-13        103       3.64
## 6       8     1 2005-03-21       1007       3.19
```

Nota que puede ser que algunas películas seleccionadas en validación no tengan evaluaciones en entrenamiento:

```r
table(is.na(dat_valida_pred$media_pred))
```

```
## 
##  FALSE 
## 776950
```

```r
dat_valida_pred <- mutate(dat_valida_pred,
        media_pred = ifelse(is.na(media_pred), media_total_e, media_pred))
```

No sucede en este ejemplo, pero si sucediera podríamos usar el promedio general de las predicciones. Evaluamos ahora el error:


```r
recm <- function(calif, pred){
  sqrt(mean((calif - pred)^2))
}
error <- dat_valida_pred |> ungroup() |>
  summarise(error = mean((calif - media_pred)^2))
error
```

```
## # A tibble: 1 × 1
##   error
##   <dbl>
## 1  1.03
```

Este error está en las mismas unidades de las calificaciones (estrellas en este caso).

---

Antes de seguir con nuestra refinación del modelo, veremos algunas
observaciones acerca del uso de escala en análisis de datos:

Cuando tratamos con datos en escala encontramos un problema técnico que es el uso distinto
de la escala por los usuarios, muchas veces **independientemente de sus gustos**

Veamos los datos de Netflix para una muestra de usuarios:



```r
# muestra de usuarios
entrena_usu <- sample(unique(dat_entrena$usuario_id), 50)
muestra_graf <- filter(dat_entrena, usuario_id %in% entrena_usu)
# medias generales por usuario, ee de la media
muestra_res <- muestra_graf |> group_by(usuario_id) |>
  summarise(media_calif = mean(calif), 
            sd_calif = sd(calif)/sqrt(length(calif)))
muestra_res$usuario_id <- reorder(factor(muestra_res$usuario_id), muestra_res$media_calif)
ggplot(muestra_res, aes(x=factor(usuario_id), y = media_calif, 
        ymin = media_calif - sd_calif, ymax = media_calif + sd_calif)) + 
  geom_linerange() + geom_point() + xlab('Usuario ID') +
  theme(axis.text.x=element_blank())
```

<img src="04-recomendacion_files/figure-html/unnamed-chunk-13-1.png" width="672" />

Y notamos que hay unos usuarios que tienen promedios por encima de $4.5$, mientras que otros
califican por debajo de $3$ en promedio. Aunque esto puede deberse a las películas que han visto,
generalmente una componente de esta variabilidad se debe a cómo usa la escala cada usuario.

- En primer lugar, quizá uno podría pensar que un modelo base consiste de simplemente
predecir el promedio de una película sobre todos los usuarios que la calificaron (sin incluir el sesgo de cada persona). Esto no funciona bien porque típicamente hay distintos patrones
de uso de la escala de calificación, que depende más de forma de uso de escala que de la calidad de los items.

Hay personas que son:

- Barcos: $5$,$5$,$5$,$4$,$4$,$5$ 
- Estrictos: $2$,$3$,$3$,$1$,$1$,$2$
- No se compromete: $3$,$3$,$3$,$3$,$4$
- Discrimina: $5$,$4$,$5$,$1$,$2$,$4$

El estilo de uso de las escalas varía por persona.
Puede estar asociado a aspectos culturales (países
diferentes usan escalas de manera diferente), quizá también de personalidad,
y a la forma de obtener las evaluaciones (cara a cara, por teléfono, internet).

Lo primero que vamos a hacer para controlar esta fuente de variación es ajustar las predicciones
dependiendo del promedio de calificaciones de cada usuario.


### (Opcional) Efectos en análisis de heterogeneidad en uso de escala

 Muchas veces se considera que tratar como numéricos a calificaciones en escala no es muy apropiado, y que el análisis no tiene por qué funcionar pues en realidad las calificaciones están en una escala ordinal. Sin embargo,

- La razón principal por las que análisis de datos en escala es difícil *no es que usemos valores numéricos para los puntos de la escala*. Si esto fuera cierto, entonces por ejemplo, transformar una variable con logaritmo también sería "malo".

- La razón de la dificultad es que generalmente tenemos que lidiar con la  **heterogeneidad** en uso de la escala antes de poder obtener resultados útiles de nuestro análisis.


Supongamos que $X_1$ y $X_2$ son evaluaciones de dos películas. Por la discusión de arriba, podríamos escribir

$$X_1 = N +S_1,$$
$$X_2 = N + S_2,$$

donde $S_1$ y $S_2$ representan el gusto por la película, y $N$ representa el nivel general
de calificaciones. Consideramos que son variables aleatorias ($N$ varía con las personas, igual que $S_1$ y $S_2$).

Podemos calcular

$$Cov(X_1,X_2)$$

para estimar el grado de correlación de *gusto por las dos películas*, como si fueran variables numéricas. Esta no es muy buena idea, pero no tanto porque se 
trate de variables ordinales, sino porque en realidad quisiéramos calcular:

$$Cov(S_1, S_2)$$

que realmente representa la asociación entre el gusto por las dos películas. El problema
es que $S_1$ y $S_2$ son variables que no observamos.

¿Cómo se relacionan estas dos covarianzas?

$$Cov(X_1,X_2)=Cov(N,N) + Cov(S_1,S_2) + Cov(N, S_2)+Cov(N,S_1)$$

Tenemos que $Cov(N,N)=Var(N)=\sigma_N ^2$, y suponiendo que el gusto
no está correlacionado con los niveles generales 
de respuesta, $Cov(N_1, S_2)=0=Cov(N_2,S_1)$, de modo que

$$Cov(X_1,X_2)= Cov(S_1,S_2) + \sigma_N^2.$$


donde $\sigma_N^2$ no tiene qué ver nada con el gusto por las películas.

De forma que al usar estimaciones de $Cov(X_1,X_2)$ para estimar $Cov(S_1,S_2)$ puede
ser mala idea porque el sesgo hacia arriba puede ser alto, especialmente si la gente varía mucho
es un sus niveles generales de calificaciones (hay muy barcos y muy estrictos).

### Ejemplo {#ejemplo}

Los niveles generales de $50$ personas:


```r
set.seed(128)
n <- 50
niveles <- tibble(persona = 1:n, nivel = rnorm(n,2))
```
Ahora generamos los gustos (latentes) por dos artículos, que suponemos
con correlación negativa:


```r
x <- rnorm(n)
gustos <- tibble(persona=1:n, gusto_1 = x + rnorm(n),
                     gusto_2 = -x + rnorm(n))
head(gustos,3)
```

```
## # A tibble: 3 × 3
##   persona gusto_1 gusto_2
##     <int>   <dbl>   <dbl>
## 1       1   0.948   0.459
## 2       2   1.15   -0.676
## 3       3  -1.31    2.58
```

```r
cor(gustos[,2:3])
```

```
##            gusto_1    gusto_2
## gusto_1  1.0000000 -0.5136434
## gusto_2 -0.5136434  1.0000000
```

Estos dos items tienen gusto correlacionado negativamente:

```r
ggplot(gustos, aes(x=gusto_1, y=gusto_2)) + geom_point() +
    geom_smooth()
```

```
## `geom_smooth()` using method = 'loess' and formula 'y ~ x'
```

<img src="04-recomendacion_files/figure-html/unnamed-chunk-16-1.png" width="480" />


Pero las mediciones no están correlacionadas:

```r
medicion_1 <- niveles$nivel + gustos$gusto_1+rnorm(n,0.3)
medicion_2 <- niveles$nivel + gustos$gusto_2+rnorm(n,0.3)
mediciones <- tibble(persona = 1:n, medicion_1, medicion_2)
cor(mediciones[,2:3])
```

```
##             medicion_1  medicion_2
## medicion_1  1.00000000 -0.05825995
## medicion_2 -0.05825995  1.00000000
```



Así que aún cuando el gusto por $1$ y $2$  están correlacionadas negativamente, las 
**mediciones** de gusto no están correlacionadas.

```r
ggplot(mediciones, aes(x=medicion_1, y=medicion_2)) +
    geom_point() + geom_smooth()
```

```
## `geom_smooth()` using method = 'loess' and formula 'y ~ x'
```

<img src="04-recomendacion_files/figure-html/unnamed-chunk-18-1.png" width="480" />

**Observaciones**: Un modelado más cuidadoso de este tipo de datos requiere más trabajo. Pero para
el trabajo usual, generalmente intentamos controlar parte de la heterogeneidad
**centrando** las calificaciones por usuario. Es decir, a cada calificación
de una persona le restamos la media de sus calificaciones, que es una estimación
del nivel general $N$. Esta idea funciona si **$k$ no es muy chico**.


Si el número de calificaciones por persona ($k$) es chico,
entonces tenemos los siguientes problemas:

- El promedio de evaluaciones es una estimación ruidosa del nivel general.

- Podemos terminar con el problema opuesto: nótese que
si $X_1,\ldots, X_k$ son mediciones de gusto distintos items, entonces
$$Cov(X_1-\bar{X}, X_2-\bar{X})=Cov(S_1-\bar{S},S_2-\bar{S}),$$
$$=Cov(S_1,S_2)-Cov(S_1,\bar{S})-Cov(S_2,\bar{S}) + Var(\bar{S})$$

Si $k$ es chica, suponiendo que los gustos no están correlacionados,
los términos intermedios puede tener valor negativo relativamente grande
( es de orden $\frac{1}{k}$), 
aún cuando el último término sea chico (de orden $\frac{1}{k^2}$)

Así que ahora las correlaciones estimadas pueden tener sesgo hacia 
abajo, especialmente si $k$ es chica.

Más avanzado, enfoque bayesiano: <https://www.jstor.org/stable/2670337>

## Modelo de referencia 

Ahora podemos plantear el modelo base de referencia. Este modelo es útil para hacer
benchmarking de intentos de predicción, como primera pieza para construcción de modelos
más complejos, y también como una manera simple de producir estimaciones cuando no hay datos suficientes para hacer otro tipo de predicción.


\BeginKnitrBlock{resumen}<div class="resumen">Si $x_{ij}$ es el gusto del usuario $i$ por la película $j$, entonces nuestra predicción
es
$$\hat{x}_{ij} = \hat{b}_j +  (\hat{a}_i-\hat{\mu} ) $$
donde $a_i$ indica un nivel general de calificaciones del usuario $i$, y $b_j$ es el nivel general de gusto por la película. </div>\EndKnitrBlock{resumen}

Usualmente ponemos:

1. Media general
$$\hat{\mu} =\frac{1}{T}\sum_{s,t} x_{s,t}$$
2. Promedio de calificaciones de usuario $i$ 
$$\hat{a}_i =\frac{1}{M_i}\sum_{t} x_{i,t} $$
3. Promedio de calificaciones de la película $j$ 
$$\hat{b}_j =\frac{1}{N_j}\sum_{s} x_{s,j}$$

También podemos escribir, en términos de desviaciones:

$$\hat{x}_{ij} = \hat{\mu}  +  \hat{c}_i +  \hat{d}_j $$
donde:

1. Media general
$$\hat{\mu} =\frac{1}{T}\sum_{s,t} x_{st}$$
2. Desviación de las calificaciones de usuario $i$ respecto a la media general
$$\hat{c}_i =\frac{1}{M_i}\sum_{t} x_{it} - \hat{\mu} $$
3. Desviación  de la película $j$ respecto a la media general
$$\hat{d_j} =\frac{1}{N_j}\sum_{s} x_{sj}- \hat{\mu}$$


Una vez que observamos una calificación $x_{ij}$, el residual del modelo de referencia es
$$r_{ij} = x_{ij} - \hat{x_{ij}}$$

### Ejercicio: modelo de referencia para Netflix {-}

Calculamos media de películas, usuarios y total:


```r
medias_usuarios <- dat_entrena |> 
    group_by(usuario_id) |>
    summarise(media_usu = mean(calif), num_calif_usu = length(calif)) |> 
    select(usuario_id, media_usu, num_calif_usu)
medias_peliculas <- dat_entrena |> 
    group_by(peli_id) |> 
    summarise(media_peli = mean(calif), num_calif_peli = length(calif)) |> 
    select(peli_id, media_peli, num_calif_peli)
media_total_e <- mean(dat_entrena$calif)
```

Y construimos las predicciones para el conjunto de validación


```r
dat_valida <- dat_valida |> 
  left_join(medias_usuarios) |>
  left_join(medias_peliculas) |>
  mutate(media_total = media_total_e) |>
  mutate(pred = media_peli + (media_usu - media_total)) |> 
  mutate(pred = ifelse(is.na(pred), media_total, pred))
```

```
## Joining, by = "usuario_id"
```

```
## Joining, by = "peli_id"
```


Nótese que cuando no tenemos predicción bajo este modelo para una combinación de usuario/película, usamos el 
promedio general (por ejemplo).

Finalmente evaluamos


```r
dat_valida |> ungroup() |> summarise(error = recm(calif, pred))
```

```
## # A tibble: 1 × 1
##   error
##   <dbl>
## 1 0.929
```

**Observación**: ¿Qué tan bueno es este resultado? De 
[wikipedia](https://en.wikipedia.org/wiki/Netflix_Prize):

> Prizes were based on improvement over Netflix's own algorithm, called Cinematch, or the previous year's score if a team has made improvement beyond a certain threshold. A trivial algorithm that predicts for each movie in the quiz set its average grade from the training data produces an RMSE of $1.0540$. Cinematch uses "straightforward statistical linear models with a lot of data conditioning".
>
>Using only the training data, Cinematch scores an RMSE of $0.9514$ on the quiz data, roughly a 10% improvement over the trivial algorithm. Cinematch has a similar performance on the test set, $0.9525$. In order to win the grand prize of $1,000,000$, a participating team had to improve this by another $10%$, to achieve $0.8572$ on the test set. Such an improvement on the quiz set corresponds to an RMSE of $0.8563$.
Aunque nótese que estrictamente hablando no podemos comparar nuestros resultados con estos números,
en los que se usa una muestra de prueba separada de películas vistas despúes del periodo de entrenamiento.


## Filtrado colaborativo: similitud

Además de usar promedios generales por película, podemos utilizar similitud de películas/personas
para ajustar predicciones según los gustos de artículos o películas similares. Este es el enfoque
más simple del filtrado colaborativo.


Comencemos entonces con la siguiente idea: Supongamos que queremos hacer una predicción
para el usuario $i$ en la película $j$, que no ha visto. Si tenemos una
medida de similitud entre películas, podríamos buscar películas *similares*
a $j$ que haya visto $i$, y ajustar la predicción según la calificación de estas películas similares.


Tomamos entonces nuestra predicción
base, que le llamamos $x_{ij}^0$ y hacemos una nueva predicción:

$$\hat{x}_{ij} = x_{ij}^0 + \frac{1}{k}\sum_{t \in N(i,j)} (x_{it} - x_{it}^0 )$$

donde $N(i,j)$ son películas similares a $j$ **que haya visto** $i$. Ajustamos $x_{ij}^0$ por el gusto promedio de películas similares a $j$, 
a partir de las predicciones base. Esto quiere decir
que si las películas similares a $j$ están evaluadas **por encima del esperado** para el usuario
$i$, entonces subimos la predicción, y bajamos la predicción cuando las películas similares
están evaluadas **por debajo de lo esperado**.

Nótese que estamos ajustando por los residuales del modelo base. Podemos también utilizar
un ponderado por gusto según similitud: si la similitud entre las películas $j$ y $t$ es $s_{jt}$,
entonces podemos usar

\begin{equation}
\hat{x}_{ij} = x_{ij}^0 + \frac{\sum_{t \in N(i,j)} s_{jt}(x_{it} - x_{it}^0 )}{\sum_{t \in N(i,j)} s_{jt}} 
(#eq:simprom)
\end{equation}

Cuando no tenemos películas similares que hayan sido calificadas por nuestro usuario,
**entonces usamos simplemente la predicción base**.


### Cálculo de similitud entre usuarios/películas {#simitems}

Proponemos utilizar la distancia coseno de las calificaciones centradas 
por usuario. Como discutimos arriba, antes de calcular similitud conviene centrar las calificaciones por usuario
para eliminar parte de la heterogeneidad en el uso de la escala.


### Ejemplo {-}


|   | SWars1| SWars4| SWars5| HPotter1| HPotter2| Twilight|
|:--|------:|------:|------:|--------:|--------:|--------:|
|a  |      5|      5|      5|        2|       NA|       NA|
|b  |      3|     NA|      4|       NA|       NA|       NA|
|c  |     NA|     NA|     NA|        5|        4|       NA|
|d  |      1|     NA|      2|       NA|        5|        4|
|e  |      4|      5|     NA|       NA|       NA|        2|

Calculamos medias por usuarios y centramos:


```r
apply(mat.cons,1, mean, na.rm=TRUE)
```

```
##        a        b        c        d        e 
## 4.250000 3.500000 4.500000 3.000000 3.666667
```

```r
mat.c <- mat.cons - apply(mat.cons,1, mean, na.rm=TRUE)
knitr::kable(mat.c, digits = 2)
```



|   | SWars1| SWars4| SWars5| HPotter1| HPotter2| Twilight|
|:--|------:|------:|------:|--------:|--------:|--------:|
|a  |   0.75|   0.75|   0.75|    -2.25|       NA|       NA|
|b  |  -0.50|     NA|   0.50|       NA|       NA|       NA|
|c  |     NA|     NA|     NA|     0.50|     -0.5|       NA|
|d  |  -2.00|     NA|  -1.00|       NA|      2.0|     1.00|
|e  |   0.33|   1.33|     NA|       NA|       NA|    -1.67|

Y calculamos similitud coseno entre películas,  **suponiendo que las películas
no evaluadas tienen calificación $0$**:


```r
sim_cos <- function(x,y){
  sum(x*y, na.rm = T)/(sqrt(sum(x^2, na.rm = T))*sqrt(sum(y^2, na.rm = T)))
}
mat.c[,1]
```

```
##          a          b          c          d          e 
##  0.7500000 -0.5000000         NA -2.0000000  0.3333333
```

```r
mat.c[,2]
```

```
##        a        b        c        d        e 
## 0.750000       NA       NA       NA 1.333333
```

```r
sim_cos(mat.c[,1], mat.c[,2])
```

```
## [1] 0.2966402
```


```r
sim_cos(mat.c[,1], mat.c[,6])
```

```
## [1] -0.5925503
```


**Observación**:

- Hacer este supuesto de valores $0$ cuando no tenemos evaluación no es lo mejor, pero 
como centramos por usuario tiene más sentido hacerlo. Si utilizaramos las calificaciones
no centradas, entonces estaríamos suponiendo que las no evaluadas están calificadas muy mal ($0$, por abajo de $1$,$2$,$3$,$4$,$5$).

- Si calculamos similitud entre *usuarios* de esta forma, las distancia coseno es simplemente el coeficiente de correlación. Nótese que estamos calculando similitud entre *items*, centrando por usuario, y esto no
es lo mismo que correlación entre columnas.


### Ejemplo: ¿cómo se ven las calificaciones de películas similares/no similares? {-}

Centramos las calificaciones por usuario y seleccionamos tres películas que
pueden ser interesantes.


```r
dat_entrena_c <- dat_entrena |>
  group_by(usuario_id) |>
  mutate(calif_c = calif - mean(calif))
## calculamos un id secuencial.
dat_entrena_c$id_seq <- as.numeric(factor(dat_entrena_c$usuario_id))
filter(pelis_nombres, str_detect(nombre,'Gremlins'))
```

```
## # A tibble: 3 × 3
##   peli_id   año nombre                                 
##     <dbl> <dbl> <chr>                                  
## 1    2897  1990 Gremlins 2: The New Batch              
## 2    6482  1984 Gremlins                               
## 3   10113  2004 The Wiggles: Whoo Hoo! Wiggly Gremlins!
```

```r
filter(pelis_nombres, str_detect(nombre,'Harry Met'))
```

```
## # A tibble: 2 × 3
##   peli_id   año nombre                                 
##     <dbl> <dbl> <chr>                                  
## 1    2660  1989 When Harry Met Sally                   
## 2   11850  2003 Dumb and Dumberer: When Harry Met Lloyd
```

```r
dat_1 <- filter(dat_entrena_c, peli_id==2897) # Gremlins 2
dat_2 <- filter(dat_entrena_c, peli_id==6482) # Gremlins 1
dat_3 <- filter(dat_entrena_c, peli_id==2660) # WHMS
```

Juntamos usuarios que calificaron cada par:


```r
comunes <- inner_join(dat_1[, c('usuario_id','calif_c')], dat_2[, c('usuario_id','calif_c')] |> rename(calif_c_2=calif_c))
```

```
## Joining, by = "usuario_id"
```

```r
comunes_2 <- inner_join(dat_1[, c('usuario_id','calif_c')], dat_3[, c('usuario_id','calif_c')] |> rename(calif_c_2=calif_c))
```

```
## Joining, by = "usuario_id"
```

Y ahora graficamos. ¿Por qué se ven bandas en estas gráficas?


```r
ggplot(comunes, aes(x=calif_c, y=calif_c_2)) + 
  geom_jitter(width = 0.2, height = 0.2, alpha = 0.5) + 
  geom_smooth() + xlab('Gremlins 2') + ylab('Gremlins 1')
```

<img src="04-recomendacion_files/figure-html/unnamed-chunk-29-1.png" width="480" />

```r
ggplot(comunes_2, aes(x=calif_c, y=calif_c_2))  + 
  geom_jitter(width = 0.2, height = 0.2, alpha = 0.5) + 
  geom_smooth() + xlab('Gremlins 2') + ylab('When Harry met Sally')
```

<img src="04-recomendacion_files/figure-html/unnamed-chunk-29-2.png" width="480" />

**Pregunta**: ¿por qué los datos se ven en bandas?

Y calculamos la similitud coseno:


```r
sim_cos(comunes$calif_c, comunes$calif_c_2)
```

```
## [1] 0.1769532
```

```r
sim_cos(comunes_2$calif_c, comunes_2$calif_c_2)
```

```
## [1] -0.3156217
```

Así que las dos Gremlins son algo similares, pero Gremlins $1$ y Harry Met Sally no son similares.

---


Podemos ahora seleccionar algunas películas y ver cuáles son películas similares que nos podrían ayudar a hacer recomendaciones:


```r
dat_entrena_2 <- dat_entrena_c |> 
  ungroup() |> 
  select(peli_id, id_seq, calif_c)
ejemplos <- function(pelicula, min_pares = 100){
  mi_peli <- filter(dat_entrena_2, peli_id==pelicula) |> 
             rename(peli_id_1 = peli_id, calif_c_1 = calif_c)
  # vamos a calcular todas las similitudes con mi_peli - esto no es buena
  # idea y discutiremos más adelante cómo evitarlo
  datos_comp <- left_join(dat_entrena_2, mi_peli) |> 
    filter(!is.na(peli_id_1) )
  # calcular similitudes
  out_sum <- datos_comp |> 
      group_by(peli_id) |>
      summarise(similitud = sim_cos(calif_c, calif_c_1), num_pares = n()) |> 
    filter(num_pares > min_pares) |> 
    left_join(pelis_nombres)
  out_sum |> arrange(desc(similitud))  
}
```

Nótese que las similitudes aparentan ser ruidosas si no filtramos por número de evaluaciones:


```r
ejemplos(8199) |> head(20) |> knitr::kable()
```

```
## Joining, by = "id_seq"
```

```
## Joining, by = "peli_id"
```



| peli_id| similitud| num_pares|  año|nombre                                |
|-------:|---------:|---------:|----:|:-------------------------------------|
|    8199| 1.0000000|      1379| 1985|The Purple Rose of Cairo              |
|    6247| 0.4858263|       431| 1984|Broadway Danny Rose                   |
|   16171| 0.4670051|       618| 1987|Radio Days                            |
|    1058| 0.3940953|       485| 1972|Play it Again Sam                     |
|    6610| 0.3814492|       106| 1965|The Pawnbroker                        |
|   17341| 0.3748542|       545| 1983|Zelig                                 |
|    1234| 0.3526710|       115| 1994|Crooklyn                              |
|   12896| 0.3512115|       754| 1994|Bullets Over Broadway                 |
|    9540| 0.3509817|       101| 1987|The Decalogue                         |
|    2599| 0.3503702|       112| 1959|Black Orpheus                         |
|   16709| 0.3480806|       342| 1980|Stardust Memories                     |
|    5577| 0.3480255|       158| 1957|Throne of Blood                       |
|   10605| 0.3479292|       148| 1976|The Front                             |
|   15808| 0.3468051|       165| 1996|Citizen Ruth                          |
|   10918| 0.3370929|       139| 1987|Black Adder III                       |
|   10601| 0.3349099|       152| 1972|The Discreet Charm of the Bourgeoisie |
|   16889| 0.3294090|       408| 1969|Take the Money and Run                |
|    6070| 0.3217371|       117| 1989|Black Adder IV                        |
|   11301| 0.3118192|       137| 1973|The Wicker Man                        |
|   11720| 0.3050482|       108| 1978|Goin' South                           |


```r
ejemplos(6807) |> head(20) |> knitr::kable()
```

```
## Joining, by = "id_seq"
```

```
## Joining, by = "peli_id"
```



| peli_id| similitud| num_pares|  año|nombre                         |
|-------:|---------:|---------:|----:|:------------------------------|
|    6807| 1.0000000|      2075| 1963|8 1/2                          |
|   16241| 0.7429705|       677| 1960|La Dolce Vita                  |
|   15303| 0.6768162|       118| 1952|Umberto D.                     |
|    9485| 0.6680970|       269| 1967|Persona                        |
|    5605| 0.6356236|       141| 1946|Children of Paradise           |
|   15786| 0.6017523|       564| 1957|Wild Strawberries              |
|    2965| 0.5878489|       760| 1957|The Seventh Seal               |
|   13377| 0.5808940|       123| 1963|Winter Light                   |
|   10276| 0.5738983|       654| 1950|Rashomon                       |
|    1708| 0.5719259|       328| 1936|Modern Times                   |
|    1735| 0.5712199|       314| 1974|Amarcord                       |
|    7912| 0.5677752|       243| 1960|L'Avventura                    |
|   12721| 0.5674579|       283| 1952|Ikiru                          |
|   10661| 0.5665439|       169| 1953|Tokyo Story                    |
|   17184| 0.5612483|       240| 1939|The Rules of the Game          |
|   10277| 0.5571376|       717| 1948|The Bicycle Thief              |
|   12871| 0.5523090|       123| 1926|Our Hospitality / Sherlock Jr. |
|    8790| 0.5516619|       112| 1929|Man with the Movie Camera      |
|     840| 0.5498725|       212| 1941|The Lady Eve                   |
|   15016| 0.5497364|       227| 1928|The Passion of Joan of Arc     |

El problema otra vez es similitudes ruidosas que provienen de pocas evaluaciones en común. 

### Ejercicio {-}
Intenta con otras películas que te interesen, y prueba usando un mínimo distinto de pares para
incluir en la lista


```r
ejemplos(11271)   |> head(20)
```

```
## Joining, by = "id_seq"
```

```
## Joining, by = "peli_id"
```

```
## # A tibble: 20 × 5
##    peli_id similitud num_pares   año nombre                                     
##      <dbl>     <dbl>     <int> <dbl> <chr>                                      
##  1   11271     1          5583  1994 Friends: Season 1                          
##  2    5309     0.944      2679  1997 Friends: Season 4                          
##  3    3078     0.938      3187  1994 The Best of Friends: Season 2              
##  4    5414     0.934      3335  1996 Friends: Season 3                          
##  5    2938     0.930      3000  1994 The Best of Friends: Season 1              
##  6   15307     0.924      2931  1996 The Best of Friends: Season 3              
##  7    8438     0.920      2903  1998 Friends: Season 5                          
##  8    7158     0.919      2094  1997 The Best of Friends: Season 4              
##  9    2942     0.913      2708  1999 Friends: Season 6                          
## 10   15689     0.912      2894  1994 The Best of Friends: Vol. 1                
## 11    9909     0.909      2167  2002 Friends: Season 9                          
## 12    5837     0.908      2554  1999 Friends: Season 7                          
## 13   16083     0.907      1960  1994 The Best of Friends: Vol. 2                
## 14    1877     0.907      3123  1995 Friends: Season 2                          
## 15    1256     0.898      1723  1994 The Best of Friends: Vol. 4                
## 16   15777     0.898      2478  2001 Friends: Season 8                          
## 17   14283     0.886      1544  1994 The Best of Friends: Vol. 3                
## 18    7780     0.858      2481  2004 Friends: The Series Finale                 
## 19   13042     0.629       416  2001 Will & Grace: Season 4                     
## 20    1915     0.623       169  2000 Law & Order: Special Victims Unit: The Sec…
```

```r
ejemplos(11929)  |> head(20)
```

```
## Joining, by = "id_seq"
## Joining, by = "peli_id"
```

```
## # A tibble: 20 × 5
##    peli_id similitud num_pares   año nombre                          
##      <dbl>     <dbl>     <int> <dbl> <chr>                           
##  1   11929     1          1955  1997 Anaconda                        
##  2   11687     0.716       274  1994 Street Fighter                  
##  3   15698     0.685       175  1995 Fair Game                       
##  4   13417     0.680       116  1997 Home Alone 3                    
##  5    1100     0.671       169  2000 Dr. T & the Women               
##  6   12149     0.671       708  1997 Speed 2: Cruise Control         
##  7   17221     0.670       645  1993 Look Who's Talking Now          
##  8    5366     0.662       139  1999 The Mod Squad                   
##  9   16146     0.654       146  2003 The Real Cancun                 
## 10    5106     0.652       129  1994 House Party 3                   
## 11   12171     0.648       452  2000 Battlefield Earth               
## 12   16283     0.645       170  1994 Cops & Robbersons               
## 13   15958     0.644       102  1994 Darkman II: The Return of Durant
## 14   12517     0.643       284  2003 Gigli                           
## 15   13607     0.642       137  1992 Stop! Or My Mom Will Shoot      
## 16    1363     0.640       200  1993 Leprechaun                      
## 17   12349     0.639       227  1993 Super Mario Bros.               
## 18    7142     0.637       118  1996 Barb Wire                       
## 19    3573     0.635       286  1993 Cop and a Half                  
## 20    5005     0.634       290  1995 Vampire in Brooklyn
```

```r
ejemplos(2660)  |> head(20)
```

```
## Joining, by = "id_seq"
## Joining, by = "peli_id"
```

```
## # A tibble: 20 × 5
##    peli_id similitud num_pares   año nombre                                     
##      <dbl>     <dbl>     <int> <dbl> <chr>                                      
##  1    2660     1         16940  1989 When Harry Met Sally                       
##  2   16722     0.509       149  2001 The Godfather Trilogy: Bonus Material      
##  3   12530     0.458      2861  2004 Sex and the City: Season 6: Part 2         
##  4    8272     0.451       187  1960 The Andy Griffith Show: Season 1           
##  5   14648     0.447       680  2003 Finding Nemo (Full-screen)                 
##  6   11975     0.441       293  2005 Mad Hot Ballroom                           
##  7   16711     0.441      3305  2003 Sex and the City: Season 6: Part 1         
##  8    4427     0.433       744  2001 The West Wing: Season 3                    
##  9   12184     0.430      2676  2002 Sex and the City: Season 5                 
## 10   13073     0.426      2414  1946 It's a Wonderful Life                      
## 11    7639     0.423       171  2004 Star Wars Trilogy: Bonus Material          
## 12   13556     0.422       923  1999 The West Wing: Season 2                    
## 13   14567     0.421       136  1959 Ben-Hur: Collector's Edition: Bonus Materi…
## 14   14550     0.420     11743  1994 The Shawshank Redemption: Special Edition  
## 15     270     0.420      3618  2001 Sex and the City: Season 4                 
## 16    3456     0.419       553  2004 Lost: Season 1                             
## 17    9909     0.418      1763  2002 Friends: Season 9                          
## 18   16674     0.414       103  1994 Forrest Gump: Bonus Material               
## 19    1542     0.410      9277  1993 Sleepless in Seattle                       
## 20   12870     0.408      9397  1993 Schindler's List
```

### Implementación 

Si queremos implementar este tipo de filtrado colaborativo (por
similitud), el ejemplo de arriba no es práctico pues tenemos que
calcular todas las posibles similitudes. Sin embargo, como nos interesa
principalmente encontrar los pares de similitud alta, podemos usar LSH:

- Empezamos haciendo LSH de las películas usando el método de hiperplanos
aleatorios como función hash (pues este es el método que captura distancias coseno bajas). 
Nuestro resultado son todos los items
o películas agrupadas en cubetas. Podemos procesar las cubetas para
eliminar falsos positivos (o items con muy pocas evaluaciones).
- Ahora queremos estimar el rating del usuario $i$ de una película $j$
que no ha visto. Extraemos las cubetas donde cae la película $j$, y 
extraemos todos los items.
- Entre todos estos items, extraemos los que ha visto el usuario $i$,
y aplicamos el promedio \@ref(eq:simprom).

**Observaciones**

- En principio, este análisis podría hacerse usando similitud entre
usuarios en lugar de items. En la práctica (ver [@mmd]), el enfoque
de similitud entre items es superior, pues similitud es un concepto
que tiene más sentido en items que en usuarios (los usuarios pueden
tener varios intereses traslapados).
- Nótese que en ningún momento tuvimos que extraer variables de
películas, imágenes, libros, etc o lo que sea que estamos recomendando.
Esta es una fortaleza del filtrado colaborativo.
- Por otro lado, cuando tenemos pocas evaluaciones o calificaciones
este método no funciona bien (por ejemplo, no podemos calcular
las similitudes pues no hay traslape a lo largo de usuarios). En
este caso, este método puede combinarse con otros (por ejemplo, agregar
una parte basado en modelos de gusto por género, año, etc.)
