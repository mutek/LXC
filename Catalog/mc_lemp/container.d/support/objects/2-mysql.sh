#!/usr/bin/env sh

echo ""
echo ">>>>>>>>>>>>>>>>>>>  "$0" <<<<<<<<<<<<<<<<<<<<< "
echo ""

MYSQL_RANDOM_PASSWORD="$(pwgen -s 25 1)"
wait

echo "$MYSQL_RANDOM_PASSWORD" > /root/mysql_pwd.txt
mysqladmin -u root password $MYSQL_RANDOM_PASSWORD
wait

MC_RC_USERPASSWORD="$(pwgen -s 25 1)"
wait
echo "$MC_RC_USERPASSWORD" > /root/mysql_roundcube_pwd.txt

MC_RC_DBNAME="roundcubemail"
MC_RC_USERNAME="roundcube"
ROOT_PWD="$(cat /root/mysql_pwd.txt)"

### ROUNDCUBE
mysql -u root --password=$ROOT_PWD -e "CREATE DATABASE roundcubemail /*!40101 CHARACTER SET utf8 COLLATE utf8_general_ci */;"
wait

mysql -u root --password=$ROOT_PWD -e "DROP USER 'roundcube'@'localhost'; FLUSH PRIVILEGES;"
wait

mysql -u root --password=$ROOT_PWD -e "CREATE USER 'roundcube'@'localhost' IDENTIFIED BY '"$MC_RC_USERPASSWORD"'; FLUSH PRIVILEGES;"
wait

mysql -u root --password=$ROOT_PWD -e "GRANT ALL PRIVILEGES ON roundcubemail.* TO 'roundcube'@'localhost'IDENTIFIED BY '"$MC_RC_USERPASSWORD"';"
wait

mysql -u root --password=$ROOT_PWD roundcubemail < /root/container.d/roundcube/mysql.initial.sql
wait




# THE FINAL CUT
mysql -u root --password=$ROOT_PWD -e 'show databases;' > /root/the_final_cut.txt
wait

