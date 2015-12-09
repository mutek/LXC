#!/usr/bin/env sh


# dominio.tld
MC_DOMINIOHOST=""

# mail
MC_NOMEHOST=""

# mail.dominio.tld
MC_NOMECOMPLETO=$MC_NOMEHOST"."$MC_DOMINIO

# se le variabili non sono state scritte dal bulder allora la volonta è di operare secondo il default del builder che
# gia provvede a scrivere l'hostname
if [ "$MC_NOMECOMPLETO" = "" ]
then
:
else

	hostname $MC_NOMECOMPLETO

	echo $MC_NOMECOMPLETO > /etc/hostname

	sed -i "1s/^/127.0.0.1 $MC_NOMECOMPLETO localhost/" /etc/hosts

fi


apt-get install --assume-yes ssl-cert
make-ssl-cert generate-default-snakeoil --force-overwrite


