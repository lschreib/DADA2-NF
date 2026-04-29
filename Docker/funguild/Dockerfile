FROM debian:stable-slim

LABEL org.opencontainers.image.vendor="National Research Council Canada" \
      org.opencontainers.image.authors="Lars Schreiber <lars.schreiber@nrc-cnrc.gc.ca>"


LABEL base_image="Debian"
LABEL software="Fasttree"
LABEL software.version="v2.2"

# Install minimal build tools
RUN apt-get update && apt-get install -y \
    wget \
    ca-certificates \
    tini \
    python3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /funguild
COPY funguild /funguild

# Put binary in PATH
ENV PATH=/funguild:$PATH

ENTRYPOINT ["tini", "--"]
CMD [ "/bin/bash" ]