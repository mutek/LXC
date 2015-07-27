#!/usr/bin/env sh

DEBIAN_FRONTEND=noninteractive apt-get install --force-yes --assume-yes -y \
  php-apc \
  php5-mcrypt \
  php5-memcache \
  php5-curl \
  php5-gd \
  php-xml-parser

wait
php5enmod mcrypt
wait

echo "expose_php = Off" >> /etc/php5/apache2/php.ini
wait

php5enmod imap


