#!/usr/bin/env sh

iptables -F
iptables -X

iptables -t nat -F
iptables -t nat -X

iptables -nL

iptables -t nat -nL

