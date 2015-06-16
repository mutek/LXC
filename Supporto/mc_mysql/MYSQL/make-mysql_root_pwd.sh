#!/usr/bin/env sh

# 0) condizione iniziale prima installazione
#	necessita del primo setup di root password

[ -f mysql_pwd.txt ] && MYSQL_PWD="$(cat ./mysql_pwd.txt)" && mysql -u root --password="$MYSQL_PWD" -e 'show databases;' && exit

# se passa oltre significa che il file della pwd non è presente, si prova a svolgere il setup
MYSQL_RANDOM_PASSWORD="$(pwgen -s 25 1)"
echo "MYSQL_RANDOM_PASSWORD = "$MYSQL_RANDOM_PASSWORD
echo $MYSQL_RANDOM_PASSWORD > mysql_rnd_pwd.txt
mysqladmin -u root password $MYSQL_RANDOM_PASSWORD || { echo "ERRORE: il setup della pwd di root è fallito" ;exit; }
wait
# alle successive modifiche 
mysql -u root --password="$MYSQL_RANDOM_PASSWORD" -e 'show databases;' && echo $MYSQL_RANDOM_PASSWORD > mysql_pwd.txt
