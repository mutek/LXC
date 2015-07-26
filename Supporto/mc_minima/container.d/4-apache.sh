#!/usr/bin/env sh


cat << EOAPACHE > /etc/apache2/conf-enabled/sicurezza.conf
# esponi al minimo
ServerTokens Prod
#
ServerSignature Off
#
EOAPACHE

a2enmod rewrite ssl
a2ensite default-ssl


