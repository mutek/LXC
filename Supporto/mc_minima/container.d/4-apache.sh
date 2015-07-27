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

[ -f /etc/apache2/mods-available/ssl.conf ] && { mv /etc/apache2/mods-available/ssl.conf /etc/apache2/mods-available/ssl.conf.$(date +%N%s); }

cat << EOSSL > /etc/apache2/mods-available/ssl.conf
# con riferimento ad:
# https://weakdh.org/sysadmin.html 
# https://hynek.me/articles/hardening-your-web-servers-ssl-ciphers/
SSLCipherSuite ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA
SSLHonorCipherOrder on
#
# escludi il buco nero
SSLProtocol all -SSLv2 -SSLv3
#
SSLOpenSSLConfCmd DHParameters "/etc/ssl/private/dhparams.pem"
EOSSL


# in fondo mv è true solo se esiste il file altrimenti NIL
mv /etc/apache2/sites-available/000-default.conf  /etc/apache2/sites-available/000-default.conf.$(date +%N%s)

# semplificazione
cat << EODEFAULT > /etc/apache2/sites-available/000-default.conf
<VirtualHost *:80>
  ServerAdmin webmaster@localhost

  DocumentRoot /var/www/html
  <Directory "/var/www/html">
    Options FollowSymLinks
    AllowOverride All
  </Directory>

  ErrorLog \${APACHE_LOG_DIR}/error.log

  # Possible values include: debug, info, notice, warn, error, crit,
  # alert, emerg.
  LogLevel warn

  CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EODEFAULT


service apache2 restart
