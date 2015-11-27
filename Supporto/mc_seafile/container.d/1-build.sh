#!/usr/bin/env sh
#
# setup doc
#
# Luca Cappelletti (c) 2015 <luca.cappelletti@positronic.ch>
#
# WTF
#


MC_CONTAINER_D_DIR="/root/container.d"


DEBIAN_FRONTEND=noninteractive  apt-get -f install --force-yes --assume-yes -y  

DEBIAN_FRONTEND=noninteractive  apt-get install --force-yes --assume-yes -y  pwgen
wait

apt-get clean


sed -i "s/Port 22/Port 2222/g" /etc/ssh/sshd_config
sed -i "s/PermitRootLogin yes/PermitRootLogin no/g" /etc/ssh/sshd_config
sed -i "s/X11Forwarding yes/X11Forwarding no/g" /etc/ssh/sshd_config

/etc/init.d/ssh restart

##############
# CLEAN ROOM #
##############

reboot



