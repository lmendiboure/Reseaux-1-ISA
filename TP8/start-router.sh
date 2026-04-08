#!/bin/sh
iptables -F
iptables -t nat -F
iptables -P FORWARD ACCEPT

sleep infinity
