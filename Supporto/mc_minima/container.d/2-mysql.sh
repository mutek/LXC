#!/usr/bin/env sh


MYSQL_RANDOM_PASSWORD="$(pwgen -s 25 1)"
wait

echo "$MYSQL_RANDOM_PASSWORD" > /root/mysql_pwd.txt
mysqladmin -u root password $MYSQL_RANDOM_PASSWORD
wait

MYSQL_MAILUSER_PWD="$(pwgen -s 25 1)"
wait
echo "$MYSQL_MAILUSER_PWD" > /root/mysql_mailuser_pwd.txt

MYSQL_MAILADMIN_PWD="$(pwgen -s 25 1)"
wait
echo "$MYSQL_MAILADMIN_PWD" > /root/mysql_mailadmin_pwd.txt

MC_RC_USERPASSWORD="$(pwgen -s 25 1)"
wait
echo "$MC_RC_USERPASSWORD" > /root/mysql_roundcube_pwd.txt

MC_RC_DBNAME="roundcubemail"
MC_RC_USERNAME="roundcube"
ROOT_PWD="$(cat /root/mysql_pwd.txt)"
DB_NAME="mailserver"
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

mysql -u root --password=$ROOT_PWD $DB_NAME < $MC_CONTAINER_D_DIR/$DB_NAME.sql
wait

mysql -u root --password=$ROOT_PWD -e  "GRANT SELECT	 ON "$DB_NAME".* TO '"$DB_USER"'@'127.0.0.1';"
wait

mysql -u root --password=$ROOT_PWD -e "DROP USER '"$DB_MAILADMIN_USER"'@'localhost'; FLUSH PRIVILEGES;"
wait

mysql -u root --password=$ROOT_PWD -e "CREATE USER '"$DB_MAILADMIN_USER"'@'localhost' IDENTIFIED BY '"$DB_MAILADMIN_PWD"'; FLUSH PRIVILEGES;"
wait

mysql -u root --password=$ROOT_PWD -e  "GRANT SELECT,INSERT,UPDATE,DELETE ON "$DB_NAME".* TO '"$DB_MAILADMIN_USER"'@'127.0.0.1';"
wait

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

