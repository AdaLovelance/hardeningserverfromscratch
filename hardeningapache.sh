#!/bin/bash

#Creado por kao 7/11/2014 bajo licencia GPL3 www.informatico-madrid.com

echo "hardening apache2 on-ubuntu-server-14-04"
echo "visitanos en www.informatico-madrid.com"

#Sólo los usarios del grupo de root pueden acceder a sudo:
dpkg-statoverride --update --add root sudo 4750 /bin/su

#Securizamos la net para los contenedores, que sean lxc implica 
#que no podemos poner algunas opciones habituales en este punto
#ya que si no dejaría de funcionar la red

cat >/etc/sysctl.d/10-network-security.conf <<EOF
# Block SYN attacks
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5

# Log Martians
net.ipv4.conf.all.log_martians = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
EOF

#reiniciamos el servicio para que coja las nuesvas configuraciones
service procps start

#Añadimos los grupos necesarios para que gestionen apache 
groupadd webadmin
groupadd webserv

#Actualización del sistema e instalación de apache
aptitude update && aptitude upgrade
aptitude install apache2 libapache2-modsecurity libapache2-mod-php5 apache2-utils

#Desabilitamos los módulos ineccesarios
# - autoindex: prove una buena lista de todos los ficheros en un directorio 
#cuyo index no ha sido dado
# - status: te ofrece un pequeños servidor de monitoreo de la página que visitas
a2dismod status
a2dismod autoindex
a2enmod headers
#copiamos la configuración de apache por defecto y ahora la modificaremos
cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf.original
cp /etc/apache2/conf-available/security.conf  /etc/apache2/conf-available/security.conf.original 

#No enviar los tokens del sistema operativo 
#No informar sobre la versión de apache 
sed -i "s|ServerTokens OS|ServerTokens Prod|g" /etc/apache2/conf-available/security.conf
sed -i "s|ServerSignature On|ServerSignature Off|g" /etc/apache2/conf-available/security.conf
sed -i "s|#Header set X-Content-Type-Options: "nosniff" |Header set X-Content-Type-Options: "nosniff"|g" /etc/apache2/conf-available/security.conf
sed -i "s|#Header set X-Frame-Options: "sameorigin"|#Header set X-Frame-Options: "sameorigin"|g" /etc/apache2/conf-available/security.conf
#Hasta aquí la configuración por default
#Empezamos con el modsecurity
mv /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf
#Activamos las reglas:
sed -i "s|SecRuleEngine DetectionOnly|SecRuleEngine On|g" /etc/modsecurity/modsecurity.conf
#Aumentamos el límite de ficheros a 16Mb
sed -i "s|SecRequestBodyLimit 13107200|SecRequestBodyLimit 16384000|g" /etc/modsecurity/modsecurity.conf

#instalamos, configuramos y activamos el módulo de seguridad de Owasp

cd /tmp
wget https://github.com/SpiderLabs/owasp-modsecurity-crs/archive/master.zip
aptitude install zip
unzip master.zip
cp -r owasp-modsecurity-crs-master/* /etc/modsecurity/
mv /etc/modsecurity/modsecurity_crs_10_setup.conf.example /etc/modsecurity/modsecurity_crs_10_setup.conf
ls /etc/modsecurity/base_rules | xargs -I {} ln -s /etc/modsecurity/base_rules/{} /etc/modsecurity/activated_rules/{}
ls /etc/modsecurity/optional_rules | xargs -I {} ln -s /etc/modsecurity/optional_rules/{} /etc/modsecurity/activated_rules/{}


cat > /etc/apache2/mods-avaiable/security2.conf<<EOF

<IfModule security2_module>
        # Default Debian dir for modsecurity's persistent data
        SecDataDir /var/cache/modsecurity

        # Include all the *.conf files in /etc/modsecurity.
        # Keeping your local configuration in that directory
        # will allow for an easy upgrade of THIS file and
        # make your life easier
        IncludeOptional /etc/modsecurity/*.conf
		Include "/etc/modsecurity/activated_rules/*.conf"
</IfModule>
EOF
service apache2 restart

a2enmod headers
a2enmod security2


<<COMMENT
si aparece este error al reiniciar:
/usr/sbin/apache2ctl: 87: ulimit: error setting limit (Operation not permitted)
abrimos el fichero /etc/security/limits.conf y añadimos las siguientes líneas:
*               soft    nofile          8192
*               hard    nofile          8192
COMMENT

#Ahora ModEvasive para denegar ddos
aptitude install libapache2-mod-evasive
mkdir /var/log/mod_evasive
chown www-data:www-data /var/log/mod_evasive

read -p "Introduce la dirección de correo donde deseas que te lleguen las alertas en caso de ddos: " correo

cat >/etc/apache2/mods-available/evasive.conf<<EOF

<IfModule mod_evasive20.c>
    DOSHashTableSize    3097
    DOSPageCount        2
    DOSSiteCount        50
    DOSPageInterval     1
    DOSSiteInterval     1
    DOSBlockingPeriod   10

    DOSEmailNotify      $correo
    #DOSSystemCommand    "su - someuser -c '/sbin/... %s ...'"
    DOSLogDir           "/var/log/mod_evasive"
</IfModule>

EOF

ln -s /etc/apache2/mods-available/evasive.conf /etc/apache2/mods-enabled/evasive.conf

service apache2 restart

echo "Thanks to http://blog.mattbrock.co.uk/hardening-the-security-on-ubuntu-server-14-04/"
