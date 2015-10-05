#!/usr/bin/env sh

useradd -r -u 150 -g mail -d /var/vmail -s /sbin/nologin -c "Gestore vmail maildir virtuali" vmail
mkdir /var/vmail
chmod 770 /var/vmail
chown vmail:mail /var/vmail
