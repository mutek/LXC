#!/usr/bin/env sh

DOMINIO="qnomos.it"
opendkim-genkey -t -b 1024 -s dkim -d $DOMINIO

chown opendkim:opendkim dkim.private

