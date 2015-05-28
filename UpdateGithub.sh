#!/usr/bin/env sh
#
# UpdateGithub.sh v1.0.2
#
#
# Copyleft )C( 2013-2015 Luca Cappelletti <luca.cappelletti@gmail.com>
#
# DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
# Version 2, December 2004
#
# Copyright (C) 2004 Sam Hocevar <sam@hocevar.net>
#
# Everyone is permitted to copy and distribute verbatim or modified
# copies of this license document, and changing it is allowed as long
# as the name is changed.
#
# DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
# TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
# 0. You just DO WHAT THE FUCK YOU WANT TO.
#

# i parametri commentati sono stati inseriti nell'hook git pre-commit
git config --global user.name "mutek"
git config --global user.email mutek@inventati.org

commento=$1
versione=$2

[ -z $1 ] && commento=""

# annota tags

echo "Aggiungo i cambiamenti al database locale"
git add -A .

echo "Eseguo la finalizzazione dei cambiamenti in locale"
EPOCA_UNIX=$(date +%N)
COMMENTO="["$EPOCA_UNIX"] "$commento
VERSIONE="v"$versione

echo "Commento transazione: "$COMMENTO
git commit -a -m "$COMMENTO"
wait

echo "Invio i cambiamenti locali al deposito remoto..."
git push origin master
wait

[ -z $2 ] || { echo"Versione: "$VERSIONE; git tag -a $VERSIONE -m "$COMMENTO"; git push origin --tags; git tag; }
wait

[ -z $2 ] && git tag

#git push origin gh-pages
echo "ok"
