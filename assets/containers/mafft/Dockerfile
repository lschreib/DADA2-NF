FROM condaforge/mambaforge:24.9.2-0

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

### LABELS ###
LABEL base_image="mambaforge"
LABEL software="MAFFT docker"
LABEL software.version="7.525"

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
    mamba create -n mafft -y mafft=7.525

RUN echo "source activate mafft" > ~/.bashrc

ENV PATH=/opt/conda/envs/mafft/bin:$PATH

ENTRYPOINT ["tini", "--"]
CMD [ "/bin/bash" ]