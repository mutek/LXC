#!/usr/bin/env sh

MC_DBNAME="mail"
MC_DBUSER="mail"
MC_DBPASSWORD="$(cat /root/mysql_mailuser_pwd.txt)"

# nome file certificato chain e nome file chiave privata
# posizionati in /etc/ssl/certs e /etc/ssl/private
# il cert finisce con .pem
# la privata con .key

MC_CERTIFICATO_CHAIN=""
MC_CERTIFICATO_KEY=""

if [ "$MC_CERTIFICATO_CHAIN" = "" ] || [ "$MC_CERTIFICATO_KEY" = "" ]
then

        MC_CERTIFICATO_CHAIN="certificato.pem"
        MC_CERTIFICATO_KEY="certificato.key"

else
:
fi


cp /root/container.d/dovecot/dovecot-sql.conf.ext  /etc/dovecot/dovecot-sql.conf.ext

sed -i "s/MC_DBPASSWORD/$MC_DBPASSWORD/g" /etc/dovecot/dovecot-sql.conf.ext

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
