#!/usr/bin/env sh


apt-get install mysql-server mysql-client

apt-get install php5-fpm php5-imap php5-mysql php5-mcrypt php5-intl nginx openssl ssl-cert

apt-get install postfix postfix-mysql libsasl2-modules libsasl2-modules-sql

service php5-fpm start

service nginx start



mkdir -p /home/clients_ssl/subdominio.dominio.tld
mkdir /home/clients_ssl/subdominio.dominio.tld/logs
mkdir /home/clients_ssl/subdominio.dominio.tld/tmp
mkdir /home/clients_ssl/subdominio.dominio.tld/www

cat << EONGINX >> subdominio.dominio.tld

server {

    listen *:443;
    server_name subdominio.dominio.tld;

    ssl on;
    ssl_certificate        /etc/nginx/certs/subdominio.dominio.tld.combined.crt;
    ssl_certificate_key    /etc/nginx/certs/subdominio.dominio.tld.key;

    root /home/clients_ssl/subdominio.dominio.tld/www;
    index index.php index.html index.htm;

    location ~ \.php$ {

        fastcgi_pass unix:/etc/php5/fpm/socks/ssl_subdominio.dominio.tld.sock;
        include fastcgi_params;
        fastcgi_param HTTPS on;

    }

    location ~ /\. {
        deny all;
    }

    access_log /home/clients_ssl/subdominio.dominio.tld/logs/access.log;
    error_log /home/clients_ssl/subdominio.dominio.tld/logs/error.log;
    error_page 404 /404.html;

}
EONGINX

mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default.ORIGINAL

ln -s /etc/nginx/sites-available/subdominio.dominio.tld_ssl /etc/nginx/sites-enabled/subdominio.dominio.tld_ssl

mkdir -p /etc/nginx/certs

service nginx restart


