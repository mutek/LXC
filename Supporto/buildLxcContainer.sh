#!/usr/bin/env bash
#  buildLxcContainer.sh v0.9
# Compila un Container LXC
# Luca Cappelletti (c) 2015 <luca.cappelletti@gmail.com>
# WTF
#
# esempio: ./buildLxcContainer.sh ServerPosta wheezy amd64
# costruisce un container di nome ServerPosta con Debian Wheezy per architetture Intel/Amd 64bit
# genera un IP statico random nella rete 10.10.10.0 associato ad un idirizzo di MAC address random

# GENERALI
NOME_CONTAINER=$1
DISTRO_RELEASE=$2
ARCHITETTURA=$3
MIRROR=$4
MAC_ADDRESS=$5
WORKING_DIR=$6
CONTAINER_STATIC_IP=$7

# verifica la presenza dei tools di comodo
[ $(which mktemp) ] || { echo "ERRORE: mktemp non trovato"; exit; }
[ $(which debootstrap) ] || { echo "ERRORE: debootstrap non trovato"; exit; }

# assegna default in caso di lacune in input
[ -z $NOME_CONTAINER ] && NOME_CONTAINER=DefaultWheezy
[ -z $DISTRO_RELEASE ] && DISTRO_RELEASE=wheezy
[ -z $ARCHITETTURA ] && ARCHITETTURA=amd64
[ -z $MIRROR ] && MIRROR="http://mirror3.mirror.garr.it/mirrors/debian/"
[ -z $MAC_ADDRESS ] && MAC_ADDRESS=$(echo 00$(od -txC -An -N5 /dev/urandom|tr \  :))
[ -z $WORKING_DIR ] && WORKING_DIR=$(mktemp -u --tmpdir=./ | cut -d"/" -f 2)
[ -z $CONTAINER_STATIC_IP ] && CONTAINER_STATIC_IP="10.10.10."$(dd if=/dev/urandom bs=1 count=1 2>/dev/null | od -An -tu1 | sed -e 's/^ *//' -e 's/  */./g')

echo "NOME_CONTAINER = "$NOME_CONTAINER
echo "DISTRO_RELEASE = "$DISTRO_RELEASE
echo "ARCHITETTURA = "$ARCHITETTURA
echo "MIRROR = "$MIRROR
echo "MAC_ADDRESS = "$MAC_ADDRESS
echo "WORKIG_DIR = "$WORKING_DIR
echo "CONTAINER_STATIC_IP = "$CONTAINER_STATIC_IP


# 0) verifica accesso alla rete
# FIX: robotica non permette ping esterno
#printf ">> accesso alla rete:"
#ping -q -w 1 -c 1 8.8.8.8 > /dev/null || { echo "ERRORE: non riesco ad accedere ad Internet"; exit; }
#wait
#printf "\t\tok\n"

# build_chroot() si preoccupa di costruire la chroot di base
build_chroot() {
ARCHITETTURA=$1
DISTRO_RELEASE=$2
WORKING_DIR=$3
MIRROR=$4

echo "build_chroot: ARCHITETTURA = "$ARCHITETTURA
echo "build_chroot: DISTRO_RELEASE = "$DISTRO_RELEASE
echo "build_chroot: WORKING_DIR = "$WORKING_DIR
echo "build_chroot: MIRROR = "$MIRROR
#echo "build_chroot()"
debootstrap --arch $ARCHITETTURA $DISTRO_RELEASE $WORKING_DIR $MIRROR || return 1
wait

return 0
}

# 1) genera chroot
printf "build_chroot():\n"
#debootstrap --arch $ARCHITETTURA $DISTRO_RELEASE $WORKING_DIR $MIRROR || {echo "ERRORE: non riesco a completare l'operazione di debootstrap"; exit; }
build_chroot $ARCHITETTURA $DISTRO_RELEASE $WORKING_DIR $MIRROR  || { echo "ERRORE: non riesco a completare l'operazione di debootstrap"; exit; }
wait
printf "build_chroot(): \t\tok\n"



# -------------------------------------------------------------------------
# 1.1) migra la chroot dalla WORKING_DIR alla rootfs del container locale
# --------------------------------------------------------------------------
# 1.1.1) crea cartella del container
printf "creo $NOME_CONTAINER"
mkdir $NOME_CONTAINER || { echo "ERRORE: non riesco a creare la cartella del Container: "$NOME_CONTAINER; echo ""; exit;}
wait
# 1.1.2) verifica la presenza della cartella del container e della cartella del rootfs
[ -d $NOME_CONTAINER ] || { echo "ERRORE: non trovo la cartella del Container: "$NOME_CONTAINER; ls --color ; exit; }
wait
printf "\t\tok\n"

# 1..1.3) sposta la chroot nella rootfs
printf "sposto chroot in rootfs"
mv $WORKING_DIR $NOME_CONTAINER/rootfs || { echo "ERRORE: non riesco a spostare la chroot da "$WORKING_DIR" a "$NOME_CONTAINER/rootfs; exit;}
wait

# 1.1.4) verifica a presenza della cartella rootfs nel container e della validita della chroot
[ -f $NOME_CONTAINER/rootfs/etc/issue ] || { echo "ERRORE: non trovo la rootfs valida in "$NOME_CONTAINER; exit; }
wait
printf "\t\tok\n"


# 2) setup network IP statico nel container
mkdir -p $NOME_CONTAINER/rootfs/etc/network || { echo "ERRORE: non riesco a creare la cartella $NOME_CONTAINER/rootfs/etc/network"; exit 0; }
cat << INTERFACES > $NOME_CONTAINER/rootfs/etc/network/interfaces
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
	address $CONTAINER_STATIC_IP
	netmask 255.255.255.0
	gateway 10.10.10.1
INTERFACES

cat $NOME_CONTAINER/rootfs/etc/network/interfaces

# 3)modifica MAC address del file config nella cartella dei metadati del container
cat << CONFIG_LXC > $NOME_CONTAINER/config
#lxc.utsname = myhostname
#lxc.network.type = veth
#lxc.network.flags = up
#lxc.network.link = br0
#lxc.network.name = eth0
#lxc.network.ipv4 = 10.2.3.1/24 10.2.3.255
#lxc.network.ipv6 = 2003:db8:1:0:214:1234:fe0b:3597
lxc.network.type = veth
lxc.network.link = lxcbr0
lxc.network.flags = up
lxc.network.hwaddr = ${MAC_ADDRESS}
lxc.rootfs = /opt/Lxc/1.1.2/Debian7/Linux/ia32/var/lib/lxc/$NOME_CONTAINER/rootfs
lxc.include = /opt/Lxc/1.1.2/Debian7/Linux/ia32/share/lxc/config/debian.common.conf
lxc.utsname = $NOME_CONTAINER
lxc.arch = $ARCHITETTURA
CONFIG_LXC

cat $NOME_CONTAINER/config
echo ""
# sed -i "s/^lxc.network.hwaddr = .*/lxc.network.hwaddr = ${MAC_ADDRESS}/g" $NOME_CONTAINER/config

# resume:

echo "NOME_CONTAINER = "$NOME_CONTAINER
echo "DISTRO_RELEASE = "$DISTRO_RELEASE
echo "ARCHITETTURA = "$ARCHITETTURA
echo "MIRROR = "$MIRROR
echo "MAC_ADDRESS = "$MAC_ADDRESS
echo "WORKIG_DIR = "$WORKING_DIR
echo "CONTAINER_STATIC_IP = "$CONTAINER_STATIC_IP

