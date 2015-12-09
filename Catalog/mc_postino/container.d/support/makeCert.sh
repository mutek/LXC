#!/usr/bin/env sh
#
# Luca Cappelletti <luca.cappelletti@positronic.ch>
#
# makeCert.sh
#
#`costruisce un semplice certificato snakeoil di test
#
#

openssl req -new -x509 -days 3650 -nodes -newkey rsa:4096 -out ./certificato.pem -keyout ./certificato.key
