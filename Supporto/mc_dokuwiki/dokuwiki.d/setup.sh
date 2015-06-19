#!/usr/bin/env sh

# 1) copia i files di supporto nella rootfs

for file_supporto in "init.sh" "dokuwiki.conf"
do

	[ -f ../$file_supporto ] || { echo "ERRORE: non trovo il file "$file_supporto" da trasferire al container"; exit; } 

	# si presuppone di ereditare le variabili di ambiente dello script che chiama: make-container
	echo " setup-database.sh: copio "$file_supporto" in "$LXC_CONFIG/$MC_NOME_CONTAINER"/rootfs/root/"
	
	[ -d $LXC_CONFIG/$MC_NOME_CONTAINER/rootfs/root ] || { echo "ERRORE: non identifico la cartella: "$LXC_CONFIG/$MC_NOME_CONTAINER"/rootfs/root/"; exit; }
	
	cp ../$file_supporto $LXC_CONFIG/$MC_NOME_CONTAINER/rootfs/root/ || { echo "ERRORE: non sono riuscito a copiare nella destinazione..."; exit;  }
	ls --color $LXC_CONFIG/$MC_NOME_CONTAINER/rootfs/root/

done


# copia rc.local
[ -f $LXC_CONFIG/$MC_NOME_CONTAINER/rootfs/etc/rc.local ] && { mv $LXC_CONFIG/$MC_NOME_CONTAINER/rootfs/etc/rc.local $LXC_CONFIG/$MC_NOME_CONTAINER/rootfs/etc/rc.local.original; }
wait
cp $LXC_CONFIG/$MC_NOME_CONTAINER/rootfs/root/init.sh $LXC_CONFIG/$MC_NOME_CONTAINER/rootfs/etc/rc.local

