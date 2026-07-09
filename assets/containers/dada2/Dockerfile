FROM rocker/r-ver:4.5.1
RUN echo 'options(repos = c(CRAN = "https://cloud.r-project.org"))' >>"${R_HOME}/etc/Rprofile.site"

LABEL org.opencontainers.image.vendor="National Research Council Canada" \
      org.opencontainers.image.authors="Lars Schreiber <lars.schreiber@nrc-cnrc.gc.ca>" \
      org.opencontainers.image.title="dada2-nf" \
      org.opencontainers.image.version="v1.1.0"

#Install necessary system packages (all the lib* things are necessary to extend the image with additional R packages)      
RUN apt-get update > /dev/null && \
    apt-get install --no-install-recommends --yes \
        wget=1.21.2-2ubuntu1.1 \
        bzip2=1.0.8-5build1 \
        ca-certificates=20230926 \
        tini=0.19.0-1 \
        cutadapt=4.2-1 \
        gzip=1.10-4+deb11u1 \
        openjdk-17-jdk=17.0.8+7-1~deb11u1 \
        libxml2=2.9.10+dfsg-6.7+deb11u9 \
        libxt6=1:1.2.0-1 \
        zlib1g-dev=1:1.2.11.dfsg-2+deb11u2 \
        libbz2-dev=1.0.8-5build1 \
        liblzma-dev=5.2.5-2.1~deb11u1 \
        libpcre3-dev=2:8.39-13 \
        libicu-dev=67.1-7 \
        libjpeg-dev=1:2.0.6-4 \
        libpng-dev=1.6.37-3-1 \
        libxml2-dev=2.9.10+dfsg-6.7+deb11u9 \
        libgdal-dev=3.2.2+dfsg-1+deb11u2 \
        libglpk-dev=4.65-1 \
        libssl-dev=1.1.1n-0+deb11u5 \
        libcurl4-openssl-dev=7.74.0-1.3+deb11u11 \
        libuv1-dev=1.40.0-1 \
        python3=3.9.2-3 \
        pip=20.0.2-5+deb11u1 \
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
RUN pip3 install --no-cache-dir --break-system-packages numpy==1.24.3 pandas==2.0.3 ete3==3.1.3

#Copy dada2 scripts into container
COPY dada2_scripts /dada2_scripts

ENTRYPOINT ["tini", "--"]
CMD [ "/bin/bash" ]