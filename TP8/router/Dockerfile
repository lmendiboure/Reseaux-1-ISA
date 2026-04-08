FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    iproute2 iptables iputils-ping net-tools curl tcpdump procps \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /router
COPY start-router.sh .
COPY bug-order.sh .
COPY bug-dnat.sh .

RUN chmod +x *.sh
