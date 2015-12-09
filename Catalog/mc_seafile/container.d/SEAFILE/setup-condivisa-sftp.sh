#!/usr/bin/env sh
#
# Luca Cappelletti (C)2015 <luca.cappelletti@positronic.ch>
#
# setup-condivisa.sh
#
# costruisce una condizione di condivisione files utilizzando accesso criptato con vista filesystem ridotto
#
# 


# senza di loro...
apt-get install openssh-server pwgen

# specifichiamo un gruppo di nome condivisa
addgroup condivisi
echo "aggiunto gruppo condivisi...se non esisteva"

# commenta il default
sed -i "s/^Subsystem sftp \/usr\/lib\/openssh\/sftp-server/#Subsystem sftp \/usr\/lib\/openssh\/sftp-server/g" /etc/ssh/sshd_config

cat << EOSFTP >> /etc/ssh/sshd_config

# configuro l'uso di sftp in modalita chroot per il gruppo condivisa
Subsystem sftp internal-sftp
Match group condivisi
ChrootDirectory %h
X11Forwarding no
AllowTcpForwarding no
ForceCommand internal-sftp
EOSFTP

# leggiamo il file di conf
service ssh restart

# se non ci sono utenti da configurare allora la configurazione termina qui...
[ ! -f /root/UTENTI_CONDIVISA ] && { echo "Non ci sono utenti da configurare in /root/UTENTI_CONDIVISA, esco..."; exit; }

mv /root/UTENTI_ABILITATI /root/UTENTI_ABILITATI.$(date +%s%N).bak
# altrimenti...
for riga in $(cat /root/UTENTI_CONDIVISA)
do
	echo "DEBUG riga="$riga
	utente=$(echo $riga | cut -d"," -f 1)
        printf "elaboro utente potenziale: $utente"
	# dovesse gia esistere, non si tocca
	nonpresente="$( cat /etc/passwd | grep ^$utente )"
	echo ""
	echo "DEBUG non presente="$nonpresente
	if [ "$nonpresente" = "" ]
	then
		segreto=$(echo $riga | cut -d"," -f 2)
		echo "segreto = "$segreto
		if [ "$segreto" = "" ]
		then
			segreto=$( pwgen -n -y -s -1 )
			echo "gen new segreto = "$segreto
		else
		:
		fi
		wait
		echo "utente: "$utente" - password="$segreto
		useradd -G condivisi -m -s /usr/bin/nologin $utente
		wait
		echo $utente":"$segreto | chpasswd
		wait
		echo $utente","$segreto >> /root/UTENTI_ABILITATI
		chown root:root /home/$utente
		mkdir -p /home/$utente/condivisa
		wait
		chown $utente:condivisi /home/$utente/condivisa
		echo " OK"

	else
	echo " skipped!"
	fi

done

echo "fine dello script"
