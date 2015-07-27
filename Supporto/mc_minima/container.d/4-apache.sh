#!/usr/bin/env sh

MC_CERTIFICATO_CHAIN=""
MC_CERTIFICATO_KEY=""

if [ "$MC_CERTIFICATO_CHAIN" = "" ] || [ "$MC_CERTIFICATO_KEY" = "" ]
then

	MC_CERTIFICATO_CHAIN="certificato.pem"
	MC_CERTIFICATO_KEY="certificato.key"

else
:
fi


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

cp /root/container.d/apache/mods-available/ssl.conf /etc/apache2/mods-available/ssl.conf


# in fondo mv è true solo se esiste il file altrimenti NIL
mv /etc/apache2/sites-available/000-default.conf  /etc/apache2/sites-available/000-default.conf.$(date +%N%s)

for elemento in $( ls /root/container.d/apache/sites-available/ )
do

	cp /root/container.d/apache/sites-available/$elemento /etc/apache2/sites-available/

done

mkdir -p /etc/apache2/sites-enabled.original
mv /etc/apache2/sites-enabled/* /etc/apache2/sites-enabled.original/

for abilitato in $(ls /etc/apache2/sites-available/ )
do

	ln -s /etc/apache2/sites-available/$abilitato /etc/apache2/sites-enabled/$abilitato

done

sed -i "s/MC_CERTIFICATO_CHAIN/$MC_CERTIFICATO_CHAIN/g" /etc/apache2/sites-available/default-ssl
wait
sed -i "s/MC_CERTIFICATO_KEY/$MC_CERTIFICATO_KEY/g" /etc/apache2/sites-available/default-ssl
wait

service apache2 restart
