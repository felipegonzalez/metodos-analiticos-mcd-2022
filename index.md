--- 
title: "Métodos analíticos, ITAM 2022"
author: "Felipe González"
email: felipexgonzalez@gmail.com
date: "2022-02-23"
site: bookdown::bookdown_site
documentclass: book
bibliography: [referencias.bib, packages.bib]
biblio-style: apalike
link-citations: yes
github-repo: felipexgonzalez/metodos-analiticos-mcd-2022
description: "Notas para métodos analíticos 2022"
---

# Temario {-}

Este curso trata sobre diversas técnicas de análisis de datos, en su mayoría diseñadas
para escalar a datos grandes. El enfoque del curso se concentra más en el entendimiento y 
aplicación de los algoritmos y los métodos, y menos en las herramientas para implementarlos. 

1. Análisis de conjuntos frecuentes
    - Algoritmo a-priori
    - Market basket analysis
2. Búsqueda de elementos similares
    - Minhashing para documentos
    - Locality Sensitive Hashing (LSH), joins aproximados
3. Sistemas de recomendación 1
    - Recomendación por contenido y filtros colaborativos
    - Factorización de matrices y dimensiones latentes
4. Reducción de dimensionalidad: DVS
    - Descomposición en valores singulares
    - Componentes principales
5. Sistemas de recomendación 2
    - Métodos basados en similitud
    - Mínimos cuadrados alternados
    - Descenso en gradiente estocástico
    - Retroalimentación implícita
6. Recuperación de información
    - Índices invertidos
    - Modelo de espacio vectorial
    - Normalización y similitud
    - Indexado semántico latente
7. Análisis de redes 1
    - Medidas de centralidad y pagerank
8. Análisis de redes 2
    - Clustering y comunidades
9. Modelos de lenguaje 1
    - N-gramas y conteos
    - Aplicaciones
10. Modelos de lenguaje 2
    - Inmersiones de palabras
    - Modelos básicos de redes neuronales
11. Aplicaciones de modelos de lenguaje
    - Corrección de ortografía, reconocimiento de idiomas
    - Clasificación de textos
12. Métodos generales de clustering

- Las notas del curso están R, y en algunos casos usamos python o línea de comandos. Puedes usar python también para hacer tareas y ejercicios. 

- Nuestro texto básico es [@mmd]. Referencias básicas adicionales son
[@jurafsky] (para procesamiento de lenguaje natural), y [sparklyr](https://therinspark.com/) para
utlizar la interfaz de R a [Spark](https://spark.apache.org). 

## Evaluación {-}

- Tareas semanales (30%)
- Examen teórico parcial (35%)
- Trabajo final (35%)
