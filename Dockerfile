FROM rocker/verse:4.1.2

ENV WORKON_HOME /opt/virtualenvs
ENV PYTHON_VENV_PATH $WORKON_HOME/ma_env
ENV SPARK_VERSION 3.1.2
ENV RENV_VERSION 0.14.0

RUN apt-get update \
    && apt-get install -y libudunits2-dev libcurl4-openssl-dev libssl-dev\
       libxml2-dev git zlib1g-dev qpdf libffi-dev apt-utils

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-dev python3-venv python3-pip

## Prepara environment de python
RUN python3 -m venv ${PYTHON_VENV_PATH}
RUN chown -R rstudio:rstudio ${WORKON_HOME}
ENV PATH ${PYTHON_VENV_PATH}/bin:${PATH}
RUN echo "PATH=${PATH}" >> /usr/local/lib/R/etc/Renviron && \
    echo "WORKON_HOME=${WORKON_HOME}" >> /usr/local/lib/R/etc/Renviron && \
    echo "RETICULATE_PYTHON_ENV=${PYTHON_VENV_PATH}" >> /usr/local/lib/R/etc/Renviron

## Because reticulate hardwires these PATHs
RUN ln -s ${PYTHON_VENV_PATH}/bin/pip /usr/local/bin/pip && \
    ln -s ${PYTHON_VENV_PATH}/bin/virtualenv /usr/local/bin/virtualenv
RUN chmod -R a+x ${PYTHON_VENV_PATH}

## Instalar renv
RUN R -e "remotes::install_github('rstudio/renv@${RENV_VERSION}')"

WORKDIR /home/rstudio
COPY renv.lock renv.lock
COPY requirements.txt requirements.txt
RUN R -e 'renv::restore()'

USER rstudio
RUN r -e 'sparklyr::spark_install(version = Sys.getenv("SPARK_VERSION"), verbose = TRUE)'
USER root

RUN ${PYTHON_VENV_PATH}/bin/activate && \
    pip install -r requirements.txt 

RUN apt-get install -y --no-install-recommends rsync

COPY --chown=rstudio:rstudio rstudio-prefs.json /home/rstudio/.config/rstudio/rstudio-prefs.json


