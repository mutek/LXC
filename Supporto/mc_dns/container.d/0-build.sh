#!/usr/bin/env sh
#
# setup
#
# Luca Cappelletti (c) 2015 <luca.cappelletti@positronic.ch>
#
# WTF
#

echo ""
echo ">>>>>>>>>>>>>>>>>>>  "$0" <<<<<<<<<<<<<<<<<<<<< "
echo ""

MC_CONTAINER_D_DIR="/root/container.d"


DEBIAN_FRONTEND=noninteractive  apt-get install --force-yes --assume-yes -y  pwgen
wait
apt-get clean


##########
# BIND 9 #
##########
DEBIAN_FRONTEND=noninteractive apt-get install --force-yes --assume-yes -y \
 bind9 \
 bind9-host \
 dnsutils

wait

#################
# T H E   E N D #
#################
echo "FINE!"
echo ""
