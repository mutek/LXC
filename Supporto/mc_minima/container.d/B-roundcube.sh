#!/usr/bin/env sh

MC_RC_DBNAME="roundcubemail"
MC_RC_DBUSER="roundcube"
MC_RC_DBPASSWORD="$(cat /root/mysql_roundcube_pwd.txt)"

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

chown -R www-data:www-data roundcube/logs
chown -R www-data:www-data roundcube/temp

sed -i "s/MC_RC_DBPASSWORD/$MC_RC_DBPASSWORD/g" /opt/roundcube/config/debian-db.php
wait

sed -i "s/MC_RC_DBUSER/$MC_RC_DBUSER/g" /opt/roundcube/config/debian-db.php
wait

sed -i "s/MC_RC_DBNAME/$MC_RC_DBNAME/g" /opt/roundcube/config/debian-db.php
wait


