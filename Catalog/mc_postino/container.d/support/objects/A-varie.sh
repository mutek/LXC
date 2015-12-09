#!/usr/bin/env sh

service postfix restart
service spamassassin restart
service clamav-daemon restart
service amavis restart
service dovecot restart
