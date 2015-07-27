#!/usr/bin/env sh

cd /opt

mv roundcube roundcube.HOLD
wait

tar -xf /root/container.d/roundcubemail-1.1.2-complete.tar.gz
wait

mv roundcubemail-1.1.2 roundcube
wait

mv roundcube/config /roundcube/config.ORIGINAL

cp -rp /root/container.d/roundcube/config roundcube/

mv roundcube/plugins /roundcube/plugins.ORIGINAL
wait

cp -rp /root/container.d/roundcube/plugins roundcube/

chown -R root:www-data roundcube/logs
chown -R root:www-data roundcube/temp

