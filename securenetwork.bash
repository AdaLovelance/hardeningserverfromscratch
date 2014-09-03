#!/bin/bash

#Este script está bajo licencia GPL y se distribuye sin garantías, copia, modifica y haz lo que quieras con él.
#Este script securiza la parte de la red, el acceso a su de los usuariaros y prevengo arp poisoning
#Creado en Ubuntu 14.04
#Creado por Kao y M 2/09/2014

echo

echo    '###############################################################################################'
echo    '#                                 Server Harden Network        			       #'
echo    '# Securizo la parte de la red, el acceso a su de los usuariaros y prevengo arp poisoning      #'
echo    '#					   BY  K&M	                                       #'
echo -e '############################################################################################### \n'
echo
echo -e "Este script securizará la red de tu servidor, puedes ver la copia \n"
echo -e "de los ficheros modificados en /root/backupf"

mkdir /root/backupf
echo "Securizando la Red Sysctl"
sleep 2

cp /etc/sysctl.conf /root/backupf

cat >> /etc/sysctl.conf <<EOF
# IP Spoofing protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Ignore ICMP broadcast requests
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Disable source packet routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# Ignore send redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Block SYN attacks
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5

# Log Martians
net.ipv4.conf.all.log_martians = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# Ignore Directed pings
net.ipv4.icmp_echo_ignore_all = 1
EOF

sysctl -p

echo "Hecho"
echo "Previniendo Ip Spoofing"
sleep 2

cp /etc/hosts /root/backupf
cat >> /etc/hosts.conf <<EOF
order bind,hosts
nospoof on
EOF

echo "Hecho"
echo "Eliminando la versión del dns"
sleep 2
cp /etc/bind/named.conf.options /root/backupf
sed -i '$ i\version "Not Disclosed";\n' /etc/bind/named.conf.options

#Solo los usuarios del grupo de root tienen acceso a sudo,
echo "Securizando usuarios"
dpkg-statoverride --update --add root sudo 4750 /bin/su

groupadd admin
read -p "¿Cuantos usuarios deben tener aceso a sudo y/o a root?, el resto serán denegados: " users

for (( i=1; i<=$users; i++ ))
do
        read -p "Introduce el nombre del usuario $1: " user
	usermod -g admin $user
done


#ARP Whatch
echo -e "Ahora se instalará arp wach para avisarnos cuando se conecta una nueva mac a nuestra red/n"
echo "Esto evita ataques de envenenamiento de rutas arp"
sleep 2

aptitude update
aptitude install arpwatch

read -p "Introduce una dirección donde deseas que te lleguen las alertas: " mail
read -p "Introduce el número de interfaces que deseas monitorizar: "  numif

cp /etc/arpwatch.conf /root/backf

for (( i=1; i<=$numif; i++ ))
do
        read -p "Introduce el nombre de la interfaz $1 seguida de la ip de red en formato 192.168.1.0/24 $2: " unaif  unaip
        losmonitorizados+=$unaif" "
	lasips+=$unaip" "
done
for a  in  $losmonitorizados
do
	for j in $lasips
	do
		cat >> /etc/arpwatch.conf <<EOF
		$a -a -n $j -m $mail
		EOF
	done
done

/etc/init.d/arpwatch start

