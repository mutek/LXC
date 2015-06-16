#!/usr/bin/env sh

# 1) copia i files di supporto nella rootfs

for file_supporto in "mailserver.sql"  "init-mysql.sh"
do

	[ -f ../$file_supporto ] || { echo "ERRORE: non trovo il file "$file_supporto" da trasferire al container"; exit; } 

	# si presuppone di ereditare le variabili di ambiente dello script che chiama: make-container
	echo " copio "$file_supporto" in "$LXC_CONFIG/$MC_NOME_CONTAINER"/rootfs/root/"
	
	[ -d $LXC_CONFIG/$MC_NOME_CONTAINER/rootfs/root ] || { echo "ERRORE: non identifico la cartella: "$LXC_CONFIG/$MC_NOME_CONTAINER"/rootfs/root/"; exit; }
	
	cp ../$file_supporto $LXC_CONFIG/$MC_NOME_CONTAINER/rootfs/root/ || { echo "ERRORE: non sono riuscito a copiare nella destinazione..."; exit;  }
	ls --color $LXC_CONFIG/$MC_NOME_CONTAINER/rootfs/root/

done

# 1.1) avvio il container

echo "Avvio il container per svolgere i lavori...attendi almeno 10 secondi per l'operazione"
lxc-start -n $MC_NOME_CONTAINER
wait
sleep 10

# 2) crea root pwd

lxc-attach -n $MC_NOME_CONTAINER -- /root/init-mysql.sh
wait
sleep 10

