FROM condaforge/mambaforge:24.9.2-0

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

### LABELS ###
LABEL base_image="mambaforge"
LABEL software="Picrust2 docker"
LABEL software.version="2.6.2"

### Basic dependency ###
RUN apt-get clean && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y  \
    build-essential \
    libc6-dev \
    tini \
    wget \
    zlib1g-dev > /dev/null && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

### install BASTA's dependencies ###
ENV PATH=/opt/conda/bin:$PATH

RUN conda config --add channels conda-forge && \
    conda config --add channels bioconda && \
    mamba create -n picrust2 -y picrust2=2.6.2

RUN echo "source activate picrust2" > ~/.bashrc

ENV PATH=/opt/conda/envs/picrust2/bin:$PATH

WORKDIR /test_data

RUN wget http://kronos.pharmacology.dal.ca/public_files/picrust/picrust2_tutorial_files/chemerin_16S_arc.tar.gz && \
    tar -xvf chemerin_16S_arc.tar.gz && \
    rm chemerin_16S_arc.tar.gz

ENTRYPOINT ["tini", "--"]
CMD [ "/bin/bash" ]