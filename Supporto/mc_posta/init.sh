#!/usr/bin/env sh
#
# init.sh > rc.local
#
# Luca Cappelletti (c) 2015 <luca.cappelletti@positronic.ch>
#
# WTF
MC_CONTAINER_MAINTAINER="Luca Cappelletti <luca.cappelletti@positronic.ch>"
DEBIAN_FRONTEND=noninteractive  apt-get install --force-yes --assume-yes -y  pwgen
wait

DEBIAN_FRONTEND=noninteractive apt-get install --force-yes --assume-yes -y libmysqlclient18 mysql-server postfix postfix-mysql swaks dovecot-mysql dovecot-pop3d dovecot-imapd dovecot-managesieved postfixadmin
wait
apt-get clean
wait
localepurge


##############################
# rollback original rc.local #
##############################
# esegue subito indiendentemente dall'esito di questo script
# in futuro verra scorporato ed eseguito esternamente
[ -f /etc/rc.local.original ] && { mv /etc/rc.local /etc/rc.local.init; } && { mv /etc/rc.local.original /etc/rc.local; }
wait

# a questo punto se presente la cartella /root/container.d allora esegui tutti gli script contenuti
# esegue eseguibili quindi il maintainer puo inserire qualsiasi materiale eseguibile
# la cartella container.d viene prodotta dal make-container
MC_CONTAINER_D_DIR="/root/container.d"
if [ -d $MC_CONTAINER_D_DIR ]
then

	for i in 
	do

		[ -x $MC_CONTAINER_D_DIR/$i ] && { $MC_CONTAINER_D_DIR/$i; }

	done

else
:
fi



exit 0
