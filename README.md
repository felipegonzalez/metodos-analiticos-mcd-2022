[![bookdown](https://github.com/felipegonzalez/metodos-analiticos-mcd-2022/actions/workflows/bookdown.yaml/badge.svg)](https://github.com/felipegonzalez/metodos-analiticos-mcd-2022/actions/workflows/bookdown.yaml)

# Métodos analíticos (ITAM, 2022)
Notas y material para el curso de Métodos Analíticos (Ciencia de Datos, ITAM).

- [Notas](https://felipegonzalez.github.io/metodos-analiticos-mcd-2022/). Estas notas son producidas
en un contenedor (con [imagen base de rocker](https://www.rocker-project.org), y limitado a unos 8G de memoria)  construido con el Dockerfile del repositorio. Para usarlo puedes hacer:

```
docker run --rm -p 8787:8787 -e PASSWORD=mipass -v /tu/carpeta/metodos-analiticos:/home/rstudio/ma-2022 felipexgonzalez/metodos-analiticos-2022:latest
```

- Para correr las notas usa el script notas/\_build.sh dentro del contenedor. Abre el archivo notas/\_book/index.html para ver tu copia local de las notas. Para usar la interfaz de Spark tienes que abrir también el puerto 4040 (ten cuidado con esto si estás corriendo esto en la nube).

- Todos los ejercicios y tareas corren también en ese contenedor. Es opcional usarlo,
pero si tienes problemas de reproducibilidad puedes intentarlo.

