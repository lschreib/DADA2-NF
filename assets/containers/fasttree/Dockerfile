FROM debian:stable-slim

LABEL org.opencontainers.image.vendor="National Research Council Canada" \
      org.opencontainers.image.authors="Lars Schreiber <lars.schreiber@nrc-cnrc.gc.ca>"


LABEL base_image="Debian"
LABEL software="Fasttree"
LABEL software.version="v2.2"

# Install minimal build tools
RUN apt-get update && apt-get install -y \
    gcc \
    wget \
    ca-certificates \
    tini \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Get FastTree source
WORKDIR /app_home
RUN wget https://morgannprice.github.io/fasttree/FastTree.c

# Compile with OpenMP (portable flags)
RUN gcc -O3 -fopenmp -o FastTree FastTree.c -lm

# Put binary in PATH
ENV PATH=/app_home:$PATH

ENTRYPOINT ["tini", "--"]
CMD [ "/bin/bash" ]