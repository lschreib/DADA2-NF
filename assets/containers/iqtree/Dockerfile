FROM debian:stable-slim

LABEL org.opencontainers.image.vendor="National Research Council Canada" \
      org.opencontainers.image.authors="Lars Schreiber <lars.schreiber@nrc-cnrc.gc.ca>"


LABEL base_image="Debian"
LABEL software="IQTree"
LABEL software.version="v3.11"

# Install minimal build tools
RUN apt-get update && apt-get install -y \
    gcc \
    wget \
    ca-certificates \
    tini \
    procps \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app_home

RUN wget https://github.com/iqtree/iqtree3/releases/download/v3.1.1/iqtree-3.1.1-Linux.tar.gz &&\
    tar -xzf iqtree-3.1.1-Linux.tar.gz && \
    mv iqtree-3.1.1-Linux iqtree && \
    rm iqtree-3.1.1-Linux.tar.gz

# Put binary in PATH
ENV PATH=/app_home/iqtree/bin:$PATH
    
ENTRYPOINT ["tini", "--"]
CMD [ "/bin/bash" ]