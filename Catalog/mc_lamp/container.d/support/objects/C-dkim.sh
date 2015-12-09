#!/usr/bin/env sh

# il dominio del cliente: dominio.tld
MC_DOMINIO=""

mv /etc/opendkim.conf /etc/opendkim.conf.ORIGINAL

cp /root/container.d/dkim/opendkim.conf /etc/

# genera la chiave e scrivi gli output in root

cd /root

# 1024 altrimenti i campi di text input web dei pannelli DNS che accettano tipicamente 255 caratteri sbroccano con chiavi da 4096
opendkim-genkey -t -b 1024 -s dkim -d $MC_DOMINIO

chown opendkim:opendkim dkim.private

mv dkim.private dkim.key

cp dkim.key /etc/ssl/private/
