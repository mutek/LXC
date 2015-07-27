#!/usr/bin/env sh
#
# setup
#
# Luca Cappelletti (c) 2015 <luca.cappelletti@positronic.ch>
#
# WTF
#


MC_CONTAINER_D_DIR="/root/container.d"

# nome dominio utilizzatore
MC_DOMINIO=""

# nome dominio host macchina
MC_DOMINIOHOST=""

MC_NOMEHOST=""
MC_NOMECOMPLETO=""

# CNAME del dominio ospitante (esempio t29 di t29.hoster.tld)
MC_HOSTNAME=""

# eventuale nome file certificato e chiave se diversa da "certificato.[pem,key]"
MC_CERTIFICATO_CHAIN=""
MC_CERTIFICATO_KEY=""

DEBIAN_FRONTEND=noninteractive  apt-get install --force-yes --assume-yes -y  pwgen
wait

apt-get clean

