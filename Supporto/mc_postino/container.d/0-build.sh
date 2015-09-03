#!/usr/bin/env sh
#
# setup
#
# Luca Cappelletti (c) 2015 <luca.cappelletti@positronic.ch>
#
# WTF
#

echo ""
echo ">>>>>>>>>>>>>>>>>>>  "$0" <<<<<<<<<<<<<<<<<<<<< "
echo ""

#########################
# HOSTNAME STUFF TO FIX #
#########################
MC_CONTAINER_D_DIR="/root/container.d"
# nome dominio utilizzatore (ad esempio: positronic.ch)
MC_DOMINIO=""
MC_DOMINIO_CLIENTE=$MC_DOMINIO
# nome dominio host macchina (ad esempio: positronic.ch)
MC_DOMINIO_HOST=""
# nome host del dominio host (ad esempio: ip100 CNAME)
MC_NOMEHOST=""
# composizione totale (ip100.positronic.ch)
MC_NOMECOMPLETO=""
# CNAME del dominio ospitante (esempio t29 di t29.hoster.tld)
MC_HOSTNAME=""
# dominio.tld
MC_DOMINIOHOST=""
# mail
MC_NOMEHOST=""
# mail.dominio.tld
MC_NOMECOMPLETO=$MC_NOMEHOST"."$MC_DOMINIO

#########################
# PARAMETRI CERTIFICATO #
#########################
C="IT"
ST="Italy"
L="Rome"
O="Positronic"
OU="Dipartimento IT"
CN="$MC_DOMINIO"


####################
# NOME CERTIFICATO #
####################
# eventuale nome file certificato e chiave se diversa da "certificato.[pem,key]"
MC_CERTIFICATO_CHAIN=""
MC_CERTIFICATO_KEY=""

DEBIAN_FRONTEND=noninteractive  apt-get install --force-yes --assume-yes -y  pwgen
wait
apt-get clean


if [ $MC_DOMINIO = "" ]
then

	echo "Attenzione per generare una chiave dkim valida è necessario un nome di dominio valido"
	echo "    della macchina che spedisce fisicamente le email (var MC_DOMINIO)"
	echo "esco!"
	exit 0

else
:
fi

# se le variabili non sono state scritte dal bulder allora la volonta è di operare secondo il default del builder che
# gia provvede a scrivere l'hostname
if [ "$MC_NOMECOMPLETO" = "" ]
then
:
else

  hostname $MC_NOMECOMPLETO

  echo $MC_NOMECOMPLETO > /etc/hostname

  sed -i "1s/^/127.0.0.1 $MC_NOMECOMPLETO localhost/" /etc/hosts

fi

#######################################
# CERTIFICATI E CRITTOGRAFIA GENERICA #
#######################################

# assicuriamoci di generare un nuovo snakeoil di emergenza
apt-get install --assume-yes ssl-cert
make-ssl-cert generate-default-snakeoil --force-overwrite


# genera in automatico un certificato self signed comprensivo quindi di csr con chiave da 8192 bit
# utilizzabile eventualmente per richiesta di certificati trusted dai root (ad esempio startssl)
cd /root
rm certificato.*
openssl genrsa -des3 -passout pass:x -out server.pass.key 8192
openssl rsa -passin pass:x -in server.pass.key -out certificato.key
rm server.pass.key
openssl req -new -key certificato.key -out certificato.csr -subj "/C=$C/ST=$ST/L=$L/O=$O/OU=$OU/CN=$CN"
openssl x509 -req -days 365 -in certificato.csr -signkey certificato.key -out certificato.pem
# posizionalo
cp certificato.pem /etc/ssl/certs/
cp certificato.key /etc/ssl/private/

###############
# MYSQL STUFF #
###############

MYSQL_RANDOM_PASSWORD="$(pwgen -s 25 1)"
wait

echo "$MYSQL_RANDOM_PASSWORD" > /root/mysql_pwd.txt
wait
mysqladmin -u root password $MYSQL_RANDOM_PASSWORD
wait

MC_RC_USERPASSWORD="$(pwgen -s 25 1)"
wait
echo "$MC_RC_USERPASSWORD" > /root/mysql_roundcube_pwd.txt

MC_RC_DBNAME="roundcubemail"
MC_RC_USERNAME="roundcube"
ROOT_PWD="$(cat /root/mysql_pwd.txt)"

# POSTFIXADMIN / DOVECOT
mysql -u root --password=$ROOT_PWD -e "CREATE DATABASE mail;"
wait

# ROUNDCUBE
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

##########
# SYSTEM #
##########
DEBIAN_FRONTEND=noninteractive apt-get install --force-yes --assume-yes -y \
  php-apc \
  php5-mcrypt \
  php5-memcache \
  php5-curl \
  php5-gd \
  php-xml-parser

wait
php5enmod mcrypt
wait
echo "expose_php = Off" >> /etc/php5/apache2/php.ini
wait
php5enmod imap
wait

if [ "$MC_CERTIFICATO_CHAIN" = "" ] || [ "$MC_CERTIFICATO_KEY" = "" ]
then

  MC_CERTIFICATO_CHAIN="certificato.pem"
  MC_CERTIFICATO_KEY="certificato.key"

else
:
fi

##########
# APACHE #
##########
mkdir -p /etc/apache2/conf-enabled
cat << EOAPACHE > /etc/apache2/conf-enabled/sicurezza.conf
# esponi al minimo
ServerTokens Prod
#
ServerSignature Off
#
EOAPACHE

a2enmod rewrite ssl
a2ensite default-ssl

service apache2 restart

[ -f /etc/apache2/mods-available/ssl.conf ] && { mv /etc/apache2/mods-available/ssl.conf /etc/apache2/mods-available/ssl.conf.$(date +%N%s); }
wait
cp /root/container.d/apache/mods-available/ssl.conf /etc/apache2/mods-available/ssl.conf
wait

# in fondo mv è true solo se esiste il file altrimenti NIL
mv /etc/apache2/sites-available/000-default.conf  /etc/apache2/sites-available/000-default.conf.$(date +%N%s)

for elemento in $( ls /root/container.d/apache/sites-available/ )
do

  cp /root/container.d/apache/sites-available/$elemento /etc/apache2/sites-available/

done

mkdir -p /etc/apache2/sites-enabled.original;wait
mv /etc/apache2/sites-enabled/* /etc/apache2/sites-enabled.original/
wait

for abilitato in $(ls /etc/apache2/sites-available/ )
do

  ln -s /etc/apache2/sites-available/$abilitato /etc/apache2/sites-enabled/$abilitato

done

sed -i "s/MC_CERTIFICATO_CHAIN/$MC_CERTIFICATO_CHAIN/g" /etc/apache2/sites-available/default-ssl
wait
sed -i "s/MC_CERTIFICATO_KEY/$MC_CERTIFICATO_KEY/g" /etc/apache2/sites-available/default-ssl
wait

# il valore puo essere instanziato in second stage 
sed -i "s/MC_DOMINIO/$MC_DOMINIO_HOST/g" /etc/apache2/sites-available/default
wait

service apache2 restart

DEBIAN_FRONTEND=noninteractive apt-get install --force-yes --assume-yes -y \
  pyzor \
  razor \
  arj \
  cabextract \
  lzop \
  nomarch \
  p7zip-full \
  ripole \
  rpm2cpio \
  tnef \
  unzip \
  unrar-free \
  zip \
  zoo \
  postgrey \
  amavis \
  clamav \
  clamav-daemon \
  spamassassin


# anti LogJam ...speriamo!
openssl dhparam -out /etc/ssl/private/dhparams.pem 2048
chmod 600 /etc/ssl/private/dhparams.pem
wait
cat /etc/ssl/private/dhparams.pem >> /etc/ssl/certs/certificato.pem

###############
# POSTFIXADIN #
###############
cd /opt
rm -rf --preserve-root postfixadmin
wait
tar -xf /root/container.d/postfixadmin-2.92.tar.gz
wait

mv postfixadmin-2.92 postfixadmin
wait

cp /root/container.d/postfixadmin/config.inc.php /opt/postfixadmin/
wait

chown -R www-data:www-data postfixadmin/templates_c
cd /var/www
ln -s /opt/postfixadmin postfixadmin

MC_DBNAME="mail"
MC_DBUSER="root"
MC_DBPASSWORD="$(cat /root/mysql_pwd.txt)"

sed -i "s/MC_DBUSER/$MC_DBUSER/g" /opt/postfixadmin/config.inc.php
sed -i "s/MC_DBPASSWORD/$MC_DBPASSWORD/g" /opt/postfixadmin/config.inc.php
sed -i "s/MC_DBNAME/$MC_DBNAME/g" /opt/postfixadmin/config.inc.php


# FINALIZZAZIONE RICHIEDE DI ANDARE IN https://dominio.tld/postfixadmin/setup.php ed inserire la pwd per prelevare l'hash ed inserirlo nel config.inc.php
# all'atto pratico sarebbe una stringa md5(random)":"sha1(md5(random)":"password)

###########
# DOVECOT #
###########
useradd -r -u 150 -g mail -d /var/vmail -s /sbin/nologin -c "Gestore vmail maildir virtuali" vmail
wait
mkdir /var/vmail
wait
chmod 770 /var/vmail
wait
chown vmail:mail /var/vmail
wait

MC_DBNAME="mail"
MC_DBUSER="root"
MC_DBPASSWORD="$(cat /root/mysql_pwd.txt)"

# nome file certificato chain e nome file chiave privata
# posizionati in /etc/ssl/certs e /etc/ssl/private
# il cert finisce con .pem
# la privata con .key


if [ "$MC_CERTIFICATO_CHAIN" = "" ] || [ "$MC_CERTIFICATO_KEY" = "" ]
then

        MC_CERTIFICATO_CHAIN="certificato.pem"
        MC_CERTIFICATO_KEY="certificato.key"

else
:
fi


cp /root/container.d/dovecot/dovecot-sql.conf.ext  /etc/dovecot/dovecot-sql.conf.ext
wait

sed -i "s/MC_DBPASSWORD/$MC_DBPASSWORD/g" /etc/dovecot/dovecot-sql.conf.ext
sed -i "s/MC_DBUSER/$MC_DBUSER/g" /etc/dovecot/dovecot-sql.conf.ext
sed -i "s/MC_DBNAME/$MC_DBNAME/g" /etc/dovecot/dovecot-sql.conf.ext


cp /root/container.d/dovecot/conf.d/10-auth.conf /etc/dovecot/conf.d/10-auth.conf
cp /root/container.d/dovecot/conf.d/10-mail.conf /etc/dovecot/conf.d/10-mail.conf

# /etc/dovecot/conf.d/10-ssl.conf
cp /root/container.d/dovecot/conf.d/10-ssl.conf /etc/dovecot/conf.d/10-ssl.conf

sed -i "s/MC_CERTIFICATO_CHAIN/$MC_CERTIFICATO_CHAIN/g" /etc/dovecot/conf.d/10-ssl.conf
sed -i "s/MC_CERTIFICATO_KEY/$MC_CERTIFICATO_KEY/g" /etc/dovecot/conf.d/10-ssl.conf

# /etc/dovecot/conf.d/10-master.conf
cp /root/container.d/dovecot/conf.d/10-master.conf /etc/dovecot/conf.d/10-master.conf

# tutto sto delirio e poi...
chown -R vmail:dovecot /etc/dovecot
chmod -R o-rwx /etc/dovecot

service dovecot restart

MC_DBNAME="mail"
MC_DBUSER="root"
MC_DBPASSWORD="$(cat /root/mysql_pwd.txt)"

if [ "$MC_HOSTNAME" = "" ]
then

  MC_HOSTNAME=$(hostname)

else
:
fi

###########
# POSTFIX #
###########

for item in $(ls /root/container.d/postfix)
do

  cp /root/container.d/postfix/$item /etc/postfix/

done

wait

# data driven availability opportunistic push
# gli errori vengono gestiti in modo naturale e trasparente dalla POSIX shell e da sed
for elemento in $(ls /etc/postfix)
do

  sed -i "s/MC_DBPASSWORD/$MC_DBPASSWORD/g" /etc/postfix/$elemento
  wait
    sed -i "s/MC_HOSTNAME/$MC_HOSTNAME/g" /etc/postfix/$elemento
  wait

done

service postfix restart
service spamassassin restart
service clamav-daemon restart
service amavis restart
service dovecot restart


#############
# ROUNDCUBE
#############
MC_RC_DBNAME="roundcubemail"
MC_RC_DBUSER="root"
MC_RC_DBPASSWORD="$(cat /root/mysql_pwd.txt)"

# RC: qualsiasi ex istanza deve essere archiviata
cd /opt
rm -rf --preserve-root roundcube
rm -rf --preserve-root roundcube.HOLD
mv roundcube roundcube.HOLD
wait

# RC: estraggo il sorgente e rinomino ad-hoc
tar -xf /root/container.d/roundcubemail-1.1.2-complete.tar.gz
wait
mv roundcubemail-1.1.2 roundcube
wait

# RC: modifico i files di configurazione
mv roundcube/config /roundcube/config.ORIGINAL
cp -rp /root/container.d/roundcube/config roundcube/
mv roundcube/plugins /roundcube/plugins.ORIGINAL
wait

cp -rp /root/container.d/roundcube/plugins roundcube/

# RC: richiede la capacita di controllo di www-data
chown -R www-data:www-data roundcube/logs
chown -R www-data:www-data roundcube/temp

# RC: config
sed -i "s/MC_RC_DBPASSWORD/$MC_RC_DBPASSWORD/g" /opt/roundcube/config/debian-db.php
wait
sed -i "s/MC_RC_DBUSER/$MC_RC_DBUSER/g" /opt/roundcube/config/debian-db.php
wait
sed -i "s/MC_RC_DBNAME/$MC_RC_DBNAME/g" /opt/roundcube/config/debian-db.php
wait

# RC: plugin password sostituisce i parametri del database
sed -i "s/MC_DBUSER/$MC_DBUSER/g" /opt/roundcube/plugins/password/config.inc.php
wait
sed -i "s/MC_DBPASSWORD/$MC_DBPASSWORD/g" /opt/roundcube/plugins/password/config.inc.php
wait
sed -i "s/MC_DBNAME/$MC_DBNAME/g" /opt/roundcube/plugins/password/config.inc.php

############
# OPENDKIM #
############

MC_DOMINIO_CLIENTE=""
mv /etc/opendkim.conf /etc/opendkim.conf.ORIGINAL
wait
cp /root/container.d/opendkim/etc/opendkim.conf /etc/

# genera la chiave e scrivi gli output in root
cd /root

# 1024 altrimenti i campi di text input web dei pannelli DNS che accettano tipicamente 255 caratteri sbroccano con chiavi da 4096
# addendum: Pannelli del calibro di Gandi permettono di modificare direttamente il file di zona ergo...chiave da 4096 va bene in generale
# 2048 è il compromesso con la verbosita
opendkim-genkey -t -b 2048 -s dkim -d $MC_DOMINIO_CLIENTE
wait
chown opendkim:opendkim dkim.private
wait
mv dkim.private dkim.key
wait
cp dkim.key /etc/ssl/private/
wait

## FINALIZZIAMO ANTIVIRUS CLAMAV
#
# scarichiamo il db

echo "CLAMAV: scarico il db dei virus aggiornati...ci vuole un po!!"
freshclam
wait

# RIAVVIAMO IL SERVER
/etc/init.d/clamav-daemon restart

/etc/init.d/clamav-freshclam restart

echo "FINE!"
echo ""
echo "p.s. ricorda che devi attivare a manina postfixadmin...ed anche roundcube non è che si sente poi cosi tanto bene..."
