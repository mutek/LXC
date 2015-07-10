#!/usr/bin/env sh
#
# setup doc
#
# Luca Cappelletti (c) 2015 <luca.cappelletti@positronic.ch>
#
# WTF
#

#
# MYSQL
#

MC_CONTAINER_D_DIR="/root/container.d"


DEBIAN_FRONTEND=noninteractive  apt-get install --force-yes --assume-yes -y  pwgen
wait

DEBIAN_FRONTEND=noninteractive apt-get install --force-yes --assume-yes -y git rsync libmysqlclient18 libjpeg62 vsftpd
wait

apt-get clean

MYSQL_RANDOM_PASSWORD="$(pwgen -s 25 1)"
wait

echo "$MYSQL_RANDOM_PASSWORD" > /root/mysql_pwd.txt
mysqladmin -u root password $MYSQL_RANDOM_PASSWORD
wait

MYSQL_MAILUSER_PWD="$(pwgen -s 25 1)"
wait
echo "$MYSQL_MAILUSER_PWD" > /root/mysql_user_pwd.txt

MYSQL_MAILADMIN_PWD="$(pwgen -s 25 1)"
wait
echo "$MYSQL_MAILADMIN_PWD" > /root/mysql_admin_pwd.txt

ROOT_PWD="$(cat /root/mysql_pwd.txt)"
DB_NAME=""
DB_USER="user"
DB_USER_PWD="$(cat /root/mysql_user_pwd.txt)"
DB_ADMIN_USER="admin"
DB_ADMIN_PWD="$(cat /root/mysql_admin_pwd.txt)"

mysql -u root --password=$ROOT_PWD -e "CREATE DATABASE IF NOT EXISTS "$DB_NAME";"
wait

mysql -u root --password=$ROOT_PWD -e "DROP USER '"$DB_USER"'@'localhost'; FLUSH PRIVILEGES;"
wait

mysql -u root --password=$ROOT_PWD -e "CREATE USER '"$DB_USER"'@'localhost' IDENTIFIED BY '"$DB_USER_PWD"'; FLUSH PRIVILEGES;"
wait

mysql -u root --password=$ROOT_PWD $DB_NAME < $MC_CONTAINER_D_DIR/$DB_NAME.sql
wait

mysql -u root --password=$ROOT_PWD -e  "GRANT SELECT	 ON "$DB_NAME".* TO '"$DB_USER"'@'127.0.0.1';"
wait

mysql -u root --password=$ROOT_PWD -e "DROP USER '"$DB_ADMIN_USER"'@'localhost'; FLUSH PRIVILEGES;"
wait

mysql -u root --password=$ROOT_PWD -e "CREATE USER '"$DB_ADMIN_USER"'@'localhost' IDENTIFIED BY '"$DB_ADMIN_PWD"'; FLUSH PRIVILEGES;"
wait

mysql -u root --password=$ROOT_PWD -e  "GRANT SELECT,INSERT,UPDATE,DELETE ON "$DB_NAME".* TO '"$DB_ADMIN_USER"'@'127.0.0.1';"
wait

mysql -u root --password=$ROOT_PWD -e 'show databases;' > /root/the_final_cut.txt
wait


##############
# CLEAN ROOM #
##############
[ -f /etc/rc.local.original ] && { mv /etc/rc.local /etc/rc.local.init; } && { mv /etc/rc.local.original /etc/rc.local; }
wait

reboot

exit 0


