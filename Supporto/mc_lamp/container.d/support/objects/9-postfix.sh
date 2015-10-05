#!/usr/bin/env sh

MC_DBNAME="mail"
MC_DBUSER="root"
MC_DBPASSWORD="$(cat /root/mysql_root_pwd.txt)"

MC_HOSTNAME=""

if [ "$MC_HOSTNAME" = "" ]
then

	MC_HOSTNAME=$(hostname)

else
:
fi

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



