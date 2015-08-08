#!/usr/bin/env sh

DEBIAN_FRONTEND=noninteractive apt-get install --force-yes --assume-yes -y \
  pyzor \
  razor \
  arj \
  cabextract \
  lzop \
  nomarch \
  p7zip-full \
  ripole \
  rpm2cpio \
  tnef \
  unzip \
  unrar-free \
  zip \
  zoo \
  postgrey \
  amavis \
  clamav \
  clamav-daemon \
  spamassassin


# anti LogJam ...speriamo!
openssl dhparam -out /etc/ssl/private/dhparams.pem 2048
chmod 600 /etc/ssl/private/dhparams.pem

wait

cat /etc/ssl/private/dhparams.pem >> /etc/ssl/certs/certificato.pem
