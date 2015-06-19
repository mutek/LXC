#!/usr/bin/env sh
#
# init.sh
#
# Luca Cappelletti (c) 2015 <luca.cappelletti@positronic.ch>
#
# WTF
#
#

MAINTAINER="Luca Cappelletti <luca.cappelletti@positronic.ch>"
DEBIAN_FRONTEND=noninteractive  apt-get install --force-yes --assume-yes -y  pwgen
wait

apt-get clean
wait

cd /

# http://download.dokuwiki.org/src/dokuwiki/dokuwiki-stable.tgz
DOKUWIKI_VERSION="2014-09-29d"
wget http://download.dokuwiki.org/src/dokuwiki/dokuwiki-stable.tgz
wait

[ -f /dokuwiki-stable.tgz ] && { tar -xvf /dokuwiki-stable.tgz; }
wait

mv "/dokuwiki-$DOKUWIKI_VERSION" /dokuwiki
wait
chown -R www-data:www-data /dokuwiki
wait

mkdir -p /etc/lighttpd/conf-available/
wait

[ -f /root/dokuwiki.conf ] && { cp /root/dokuwiki.conf /etc/lighttpd/conf-available/20-dokuwiki.conf; }
wait

lighty-enable-mod dokuwiki fastcgi accesslog
wait

mkdir /var/run/lighttpd && chown www-data.www-data /var/run/lighttpd
wait

RUN="/usr/sbin/lighttpd -D -f /etc/lighttpd/lighttpd.conf"

##############
# CLEAN ROOM #
##############
[ -f /etc/rc.local.original ] && { mv /etc/rc.local /etc/rc.local.init; } && { mv /etc/rc.local.original /etc/rc.local; }
wait

sed -i "s/exit 0//g" /etc/rc.local
wait

echo "" >> /etc/rc.local
echo "/usr/sbin/lighttpd -D -f /etc/lighttpd/lighttpd.conf" >> /etc/rc.local
echo "" >> /etc/rc.local
echo "exit 0" >> /etc/rc.local

/etc/init.d/lighttpd restart
wait
sleep 2
reboot

### rc.local vuole questo
exit 0


