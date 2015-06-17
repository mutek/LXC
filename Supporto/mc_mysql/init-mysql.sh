#!/usr/bin/env sh
#
# setup-mysql.sh
#
# Luca Cappelletti (c) 2015 <luca.cappelletti@positronic.ch>
#
# WTF
#
# 
# questo codice effettua una tabula rasa del database precedente in modo puramente opportunistico
# e poi ricostruisce secondo lo schema fornito
#
# si aspetta un mysql configurato con utente root e relativa pwd

DEBIAN_FRONTEND=noninteractive  apt-get install --force-yes --assume-yes -y  pwgen
wait

#cd /root

#echo " init-mysql: stop mysql"
#/etc/init.d/mysql stop
#wait
#sleep 10
#echo " init-mysql: start mysql"
#/etc/init.d/mysql start
#wait

#pstree

[ -f /root/mysql_pwd.txt ] && MYSQL_PWD="$(cat /root/mysql_pwd.txt)" && mysql -u root --password="$MYSQL_PWD" -e 'show databases;' && exit

# mailuser password
[ -f /root/mysql_mailuser_pwd.txt ] && MYSQL_MAILUSER_PWD="$(cat /root/mysql_mailuser_pwd.txt)"

# se passa oltre significa che il file della pwd non è presente, si prova a svolgere il setup
MYSQL_RANDOM_PASSWORD="$(pwgen -s 25 1)"
wait
echo " init-mysql.sh: MYSQL_RANDOM_PASSWORD = "$MYSQL_RANDOM_PASSWORD
echo $MYSQL_RANDOM_PASSWORD > /root/mysql_pwd.txt
mysqladmin -u root password $MYSQL_RANDOM_PASSWORD || { echo "ERRORE: il setup della pwd di root è fallito" ;exit; }
wait
# alle successive modifiche 
mysql -u root --password="$MYSQL_RANDOM_PASSWORD" -e 'show databases;' && echo $MYSQL_RANDOM_PASSWORD > /root/mysql_pwd.txt
wait

MYSQL_MAILUSER_PWD="$(pwgen -s 25 1)"
wait
echo " init-mysql.sh: MYSQL_MAILUSER_PWD = "$MYSQL_MAILUSER_PWD
echo $MYSQL_MAILUSER_PWD > /root/mysql_mailuser_pwd.txt

ROOT_PWD="$(cat /root/mysql_pwd.txt)"
DB_NAME="mailserver"
DB_USER="mailuser"
DB_USER_PWD="$(cat /root/mysql_mailuser_pwd.txt)"

[ -f /root/$DB_NAME.sql ] || { echo "ERRORE: non trovo il file "$DB_NAME".sql"; exit; }

echo " init-mysql.sh: eseguo le chiamate mysql..."
mysql -u root --password=$ROOT_PWD -e "CREATE DATABASE IF NOT EXISTS "$DB_NAME";"
wait

mysql -u root --password=$ROOT_PWD -e "DROP USER '"$DB_USER"'@'localhost'; FLUSH PRIVILEGES;"
wait

mysql -u root --password=$ROOT_PWD -e "CREATE USER '"$DB_USER"'@'localhost' IDENTIFIED BY '"$DB_USER_PWD"'; FLUSH PRIVILEGES;"
wait

mysql -u root --password=$ROOT_PWD mailserver < /root/mailserver.sql
wait

mysql -u root --password=$ROOT_PWD -e  "GRANT SELECT,INSERT,UPDATE,DELETE ON "$DB_NAME".* TO '"$DB_USER"'@'localhost';"
wait

echo " init-mysql.sh: script init-mysql.sh end"
mysql -u root --password=$ROOT_PWD -e 'show databases;' > /root/the_final_print.txt
wait

[ -f /etc/rc.local.original ] && { mv /etc/rc.local /etc/rc.local.init; } && { mv /etc/rc.local.original /etc/rc.local; }
wait

exit 0
