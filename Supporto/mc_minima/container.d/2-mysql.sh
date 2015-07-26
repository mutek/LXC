#!/usr/bin/env sh

DEBIAN_FRONTEND=noninteractive apt-get install --force-yes --assume-yes -y git rsync libmysqlclient18 libjpeg62

MYSQL_RANDOM_PASSWORD="$(pwgen -s 25 1)"
wait

echo "$MYSQL_RANDOM_PASSWORD" > /root/mysql_root_pwd.txt
mysqladmin -u root password $MYSQL_RANDOM_PASSWORD
wait

MYSQL_MAILUSER_PWD="$(pwgen -s 25 1)"
wait
echo "$MYSQL_MAILUSER_PWD" > /root/mysql_mailuser_pwd.txt

MYSQL_MAILADMIN_PWD="$(pwgen -s 25 1)"
wait
echo "$MYSQL_MAILADMIN_PWD" > /root/mysql_mailadmin_pwd.txt

ROOT_PWD="$(cat /root/mysql_root_pwd.txt)"
DB_NAME="mail"
DB_USER="mailuser"
DB_USER_PWD="$(cat /root/mysql_mailuser_pwd.txt)"
DB_MAILADMIN_USER="mailadmin"
DB_MAILADMIN_PWD="$(cat /root/mysql_mailadmin_pwd.txt)"

mysql -u root --password=$ROOT_PWD -e "CREATE DATABASE IF NOT EXISTS "$DB_NAME";"
wait

mysql -u root --password=$ROOT_PWD -e "DROP USER '"$DB_USER"'@'localhost'; FLUSH PRIVILEGES;"
wait

mysql -u root --password=$ROOT_PWD -e "CREATE USER '"$DB_USER"'@'localhost' IDENTIFIED BY '"$DB_USER_PWD"'; FLUSH PRIVILEGES;"
wait

mysql -u root --password=$ROOT_PWD -e  "GRANT ALL ON "$DB_NAME".* TO '"$DB_USER"'@'localhost'IDENTIFIED BY '"$DB_MAILADMIN_PWD"';"
wait

mysql -u root --password=$ROOT_PWD -e 'show databases;' > /root/the_final_cut.txt
wait