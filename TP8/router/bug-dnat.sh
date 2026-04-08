#!/bin/sh
iptables -F
iptables -t nat -F
iptables -P FORWARD ACCEPT

iptables -t nat -A PREROUTING -p tcp --dport 8080 \
  -j DNAT --to-destination 10.20.0.99:8000

sleep infinity
