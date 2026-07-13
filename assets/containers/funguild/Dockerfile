FROM debian:stable-slim

LABEL org.opencontainers.image.vendor="National Research Council Canada" \
    org.opencontainers.image.authors="Lars Schreiber <lars.schreiber@nrc-cnrc.gc.ca>" \
    org.opencontainers.image.title="DADA2-NF FUNGuild runtime" \
    org.opencontainers.image.version="1.1+dada2nf.2"

# Install minimal runtime tools
RUN apt-get update && apt-get install --no-install-recommends -y \
    wget \
    ca-certificates \
    tini \
    python3 \
    procps \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# INstall Python dependencies
RUN pip3 install --break-system-packages requests

WORKDIR /funguild
COPY funguild /funguild

# Put binary in PATH
ENV PATH=/funguild:$PATH

ENTRYPOINT ["tini", "--"]
CMD [ "/bin/bash" ]