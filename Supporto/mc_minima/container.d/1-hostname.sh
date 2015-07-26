#!/usr/bin/env sh


DOMINIO="dominio.com"
NOMEHOST="mail"
NOMECOMPLETO=$NOMEHOST"."$DOMINIO

hostname $NOMECOMPLETO

echo $NOMECOMPLETO > /etc/hostname

sed -i "1s/^/127.0.0.1 $NOMECOMPLETO localhost/" /etc/hosts

apt-get install --assume-yes ssl-cert
make-ssl-cert generate-default-snakeoil --force-overwrite


