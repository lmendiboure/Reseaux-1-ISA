#!/bin/sh
iptables -F
iptables -t nat -F
iptables -P FORWARD ACCEPT

iptables -A FORWARD -j DROP
iptables -A FORWARD -s 10.10.0.0/24 -d 10.20.0.0/24 -j ACCEPT

sleep infinity
