#!/usr/bin/env sh

# con jessie ristabilisce la calma
apt-get -f install

DEBIAN_FRONTEND=noninteractive  apt-get -f install --force-yes --assume-yes -y 
wait

DEBIAN_FRONTEND=noninteractive  apt-get -f install --force-yes --assume-yes -y ca-certificates
wait

update-rc.d nginx defaults

apt-get -f install
