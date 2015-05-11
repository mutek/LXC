#!/usr/bin/env sh
# Luca Cappelletti <luca.cappelletti@gmail.com>
# last-stage.sh esegue degli affinamenti nella macchina
#		a valle della creazione del container
#		puo essere eseguito in chroot, non necessita di avviamento del container
#

apt-get clean
apt-get autoclean
apt-get autoremove

apt-get --yes --force-yes install htop \
 nmap \
 nano \
 sshguard \
 fail2ban \
 firmware-linux \
 firmware-linux-free \
 firmware-linux-nonfree \
 bridge-utils \
 ebtables \
 quagga \
 iptables \
 iproute \
 iproute2 \
 busybox \
 udhcpc \
 udhcpd \
 vlan \
 iperf \
 traceroute \
 tcptraceroute \
 tcpdump \
 radvd \
 rfkill \
 macchanger \
 localepurge

apt-get clean
apt-get autoclean
apt-get autoremove


