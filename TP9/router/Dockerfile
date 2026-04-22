FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    iproute2 \
    iptables \
    iputils-ping \
    net-tools \
    curl \
    tcpdump \
    dnsutils \
    procps \
    && rm -rf /var/lib/apt/lists/*
