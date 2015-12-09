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
# si aspetta unmysql configurato con utente root e relativa pwd

ROOT_PWD="fKbiDKlgZP6WHq12e5lnN1GDf"
DB_NAME="mailserver"
DB_USER="mailuser"
DB_USER_PWD="una_password_scontata_sdsds_sdds"

[ -f $DB_NAME.sql ] || { echo "ERRORE: non trovo il file "$DB_NAME".sql"; exit; }

mysql -u root --password=$ROOT_PWD -e "CREATE DATABASE IF NOT EXISTS "$DB_NAME";"
wait

mysql -u root --password=$ROOT_PWD -e "DROP USER '"$DB_USER"'@'localhost'; FLUSH PRIVILEGES;"
wait

mysql -u root --password=$ROOT_PWD -e "CREATE USER '"$DB_USER"'@'localhost' IDENTIFIED BY '"$DB_USER_PWD"'; FLUSH PRIVILEGES;"
wait

mysql -u root --password=$ROOT_PWD mailserver < mailserver.sql
wait

mysql -u root --password=$ROOT_PWD -e  "GRANT SELECT,INSERT,UPDATE,DELETE ON "$DB_NAME".* TO '"$DB_USER"'@'localhost';"
wait


