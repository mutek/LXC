#!/usr/bin/env sh

MC_DBNAME="mail"
MC_DBUSER="root"
MC_DBPASSWORD="$(cat /root/mysql_root_pwd.txt)"

cd /opt

rm -rf --preserve-root roundcube
rm -rf --preserve-root roundcube.HOLD

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

sed -i "s/MC_DBPASSWORD/$MC_DBPASSWORD/g" /opt/roundcube/config/debian-db.php
wait

sed -i "s/MC_DBUSER/$MC_DBUSER/g" /opt/roundcube/config/debian-db.php
wait

sed -i "s/MC_DBNAME/$MC_DBNAME/g" /opt/roundcube/config/debian-db.php
wait
