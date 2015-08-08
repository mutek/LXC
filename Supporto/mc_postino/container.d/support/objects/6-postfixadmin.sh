#!/usr/bin/env sh

cd /opt

rm -rf --preserve-root postfixadmin

tar -xf /root/container.d/postfixadmin-2.92.tar.gz

mv postfixadmin-2.92 postfixadmin

cp /root/container.d/postfixadmin/config.inc.php /opt/postfixadmin/

chown -R www-data:www-data postfixadmin/templates_c

cd /var/www

ln -s /opt/postfixadmin postfixadmin

MC_DBNAME="mail"
MC_DBUSER="root"
MC_DBPASSWORD="$(cat /root/mysql_root_pwd.txt)"

sed -i "s/MC_DBUSER/$MC_DBUSER/g" /opt/postfixadmin/config.inc.php
sed -i "s/MC_DBPASSWORD/$MC_DBPASSWORD/g" /opt/postfixadmin/config.inc.php
sed -i "s/MC_DBNAME/$MC_DBNAME/g" /opt/postfixadmin/config.inc.php



#------------------
# FINALIZZAZIONE RICHIEDE DI ANDARE IN https://dominio.tld/postfiadmin/setup.php ed inserire la pwd per prelevare l'hash ed inserirlo nel config.inc.php
#
# all'atto pratico sarebbe una stringa md5(random)":"sha1(md5(random)":"password)
#-------------------
