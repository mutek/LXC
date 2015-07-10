#!/usr/bin/env sh
#
# setup doc
#
# Luca Cappelletti (c) 2015 <luca.cappelletti@positronic.ch>
#
# WTF
#


MC_CONTAINER_D_DIR="/root/container.d"


DEBIAN_FRONTEND=noninteractive  apt-get install --force-yes --assume-yes -y  pwgen
wait

apt-get clean


sed -i "s/Port 22/Port 2222/g" /etc/ssh/sshd_config
sed -i "PermitRootLogin yes/PermitRootLogin no" /etc/ssh/sshd_config
sed -i "X11Forwarding yes/X11Forwarding no" /etc/ssh/sshd_config


##############
# CLEAN ROOM #
##############
[ -f /etc/rc.local.original ] && { mv /etc/rc.local /etc/rc.local.init; } && { mv /etc/rc.local.original /etc/rc.local; }
wait

reboot

exit 0


