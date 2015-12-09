#!/usr/bin/env sh
#
# setup mc_lamp
#
# Luca Cappelletti (c) 2015 <luca.cappelletti@positronic.ch>
#
# WTF
#

echo ""
echo ">>>>>>>>>>>>>>>>>>>  "$0" <<<<<<<<<<<<<<<<<<<<< "
echo ""

MC_CONTAINER_D_DIR="/root/container.d"

#########################
# HOSTNAME STUFF TO FIX #
#########################
# nome dominio utilizzatore (ad esempio: positronic.ch)
MC_DOMINIO=""
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
MC_DOMINIO_CLIENTE=$MC_NOMECOMPLETO

# gli insiemi di intervento possono essere almeno due: ospitante ed ospite che possono anche coincidere

# HOSTER
# nome host ospitante ( cname )
MC_NOMEHOST_HOSTER=""
# nome dominio ospitante (i.e. ospitante.tld)
MC_NOMEDOMINIO_HOSTER=""

# GUEST
# nome host ospite ( i.e cname )
MC_NOMEHOST_GUEST=""
# nome dominio ospite ( ospite.tld)
MC_NOMEDOMINIO_GUEST=""




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

ROOT_PWD="$(cat /root/mysql_pwd.txt)"

# MYSQL: THE FINAL CUT
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
  zoo


# anti LogJam ...speriamo!
openssl dhparam -out /etc/ssl/private/dhparams.pem 2048
chmod 600 /etc/ssl/private/dhparams.pem
wait
cat /etc/ssl/private/dhparams.pem >> /etc/ssl/certs/certificato.pem

#############
# MEMCACHED #
#############
cp /root/container.d/etc/default/memcached /etc/default/memcached

#########################
# BASIC SFTP CHROOT I/O #
#########################

### SFTP CHROOT

#8<----8<----8<----8<----8<----
#Subsystem sftp internal-sftp
#
#Match Group sftpchroot
#   ChrootDirectory /home/%u
#   ForceCommand internal-sftp
#   AllowTcpForwarding no
#   PermitTunnel no
#   X11Forwarding no
#---->8---->8---->8---->8---->8

# E' necessario creare un utente che sottende il gruppo sftpchroot

#adduser webmaster
#wait
#addgroup sftpchroot
#wait
#adduser webmaster sftpchroot


# crea la cartella di lavoro web ad esempio nel gruppo sftpchroot e utente webmaster che puo scrivere quindi:

#mkdir -p /var/www/html/www.dominio.tld
#chown -R webmaster:sftpchroot /var/www/html/www.dominio.tld

# cambia owner della cartella principale chroot di sftp per l'utente chroot che deve essere root

#chown root:root /home/webmaster

# crea ancoraggio per il mount bind verso la cartella utente chroot

#mkdir -p /home/webmaster/www.dominio.tld

# e cambia owner e gruppo in
#chown -R webmaster:sftpchroot /home/webmaster/www.dominio.tld

# a questo punto puoi aggiungere in rc.local questa riga che monta il bind automaticamente ad ogni reboot
#mount --bind /var/www/html/www.dominio.tld /home/webmaster/www.dominio.tld



#################
# T H E   E N D #
#################
echo "FINE!"
echo ""
