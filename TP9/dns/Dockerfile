FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    dnsmasq \
    iproute2 \
    iputils-ping \
    net-tools \
    tcpdump \
    procps \
    && rm -rf /var/lib/apt/lists/*

COPY dnsmasq.conf /etc/dnsmasq.conf
