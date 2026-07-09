FROM rocker/r-ver:4.5.1
RUN echo 'options(repos = c(CRAN = "https://cloud.r-project.org"))' >>"${R_HOME}/etc/Rprofile.site"

LABEL org.opencontainers.image.vendor="National Research Council Canada" \
      org.opencontainers.image.authors="Lars Schreiber <lars.schreiber@nrc-cnrc.gc.ca>" \
      org.opencontainers.image.title="dada2-nf" \
      org.opencontainers.image.version="v1.1.0"

#Install necessary system packages (lib* packages are required for additional R packages)
RUN apt-get update > /dev/null && \
    apt-get install --no-install-recommends --yes \
        wget \
        bzip2 \
        ca-certificates \
        tini \
        cutadapt \
        gzip \
        openjdk-17-jdk \
        libxml2 \
        libxt6 \
        zlib1g-dev \
        libbz2-dev \
        liblzma-dev \
        libpcre3-dev \
        libicu-dev \
        libjpeg-dev \
        libpng-dev \
        libxml2-dev \
        libgdal-dev \
        libglpk-dev \
        libssl-dev \
        libcurl4-openssl-dev \
        libuv1-dev \
        python3 \
        pip \
        > /dev/null && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

#Install necessary R packages
RUN set -e && \
    install2.r optparse R.utils readr BiocManager ggplot2 remotes vegan && \
    R -e 'BiocManager::install(c("ShortRead","Biostrings","dada2","phyloseq","DECIPHER","sangerseqR"), ask = F)' && \
    R -e 'remotes::install_github("jbisanz/qiime2R")' && \
    R -e 'remotes::install_github("mammerlin/sangeranalyseR")' && \
    rm -rf /tmp/downloaded_packages

# Install numpy and pandas using pip
RUN pip3 install --break-system-packages numpy pandas ete3

#Copy dada2 scripts into container
COPY dada2_scripts /dada2_scripts

ENTRYPOINT ["tini", "--"]
CMD [ "/bin/bash" ]