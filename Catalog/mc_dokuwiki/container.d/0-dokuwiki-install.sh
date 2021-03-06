#!/usr/bin/env sh
#
# dokuwiki fine tuning
#
# Luca Cappelletti (c) 2015 <luca.cappelletti@positronic.ch>
#
# public domain || wtf 
# quella delle due piu permissiva

cd /root/container.d

apt-get install wget

# http://download.dokuwiki.org/src/dokuwiki/dokuwiki-stable.tgz
DOKUWIKI_VERSION="2014-09-29d"

# se gia presente non riscaricare, potrebbe essere stato fornito dal maintainer
[ ! -f /root/container.d/dokuwiki-stable.tgz ] && { wget http://download.dokuwiki.org/src/dokuwiki/dokuwiki-stable.tgz; }
wait


# comincia il fine tuning per dokuwiki
cd /
[ -f /root/container.d/dokuwiki-stable.tgz ] && { tar -xvf /root/container.d/dokuwiki-stable.tgz; }
wait

mv "/dokuwiki-$DOKUWIKI_VERSION" /dokuwiki
wait
chown -R www-data:www-data /dokuwiki
wait

mkdir -p /etc/lighttpd/conf-available/
wait

[ -f /root/container.d/dokuwiki.conf ] && { cp /root/container.d/dokuwiki.conf /etc/lighttpd/conf-available/20-dokuwiki.conf; }
wait

lighty-enable-mod dokuwiki fastcgi accesslog
wait

mkdir /var/run/lighttpd && chown www-data.www-data /var/run/lighttpd
wait

RUN="/usr/sbin/lighttpd -D -f /etc/lighttpd/lighttpd.conf"

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
