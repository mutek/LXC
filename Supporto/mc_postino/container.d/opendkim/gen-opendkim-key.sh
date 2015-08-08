#!/usr/bin/env sh
#
# Luca Cappelletti (c) 2015 <luca.cappelletti@positronic.ch>
#
# un banale generatore di chiavi dkim
#
# ATTENZIONE alcuni registers hanno dei limiti a 255 caratteri nel campo input web per
#            l'inserimento del TXT nel DNS, questo limita la scelta del numero di bit
#            nel generatore che con 1024 viene acettato (4096 supera i 255 caratteri)
#
DOMINIO="dominio.tld"
opendkim-genkey -t -b 1024 -s dkim -d $DOMINIO

chown opendkim:opendkim dkim.private

