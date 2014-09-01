#!/bin/bash
#Este script está bajo licencia GPL y se distribuye sin garantías, copia, modifica y haz lo que quieras con él.
#Este script configura los requisitos mínimos de seguridad de un servidor, creado en Ubuntu 14.04


##aptitude update && aptitude upgrade
echo "Todos los ficheros modificados durante la ejecución se guardarán en /root/backupf"
mkdir /root/backupf

#Modificando el /etc/issue.net
cp /etc/issue.net /root/backupf
echo "Private Server Unknown Release" > /etc/issue.net

#Instalando Configurando y securizando SSH
read -p "Introduce un puerto para ssh por encima de 1024 " puerto
read -p "Introduce un usuario que no sea root para permitirle acceso por ssh " user
cp /etc/ssh/sshd_config /root/backupf/sshd_config.backup

rm -rf /etc/ssh/sshd_config

aptitude install openssh-server && aptitude reinstall openssh-server

cp /etc/ssh/sshd_config /root/backupf/sshd_config.default
cd /etc/ssh

sed -i "s|Port 22|Port $puerto |g" sshd_config
sed -i "s|PermitRootLogin without-password|PermitRootLogin no |g" sshd_config
sed -i "s|LoginGraceTime 120|LoginGraceTime 30 |g" sshd_config

echo "AllowUsers $user" >> /etc/ssh/sshd_config

service ssh reload

#Fin de la configuración ssh


#Instalaciones
echo -e "Instalando Trypwire para verificaión de archivos, Logrotate para la gestión de logs,
ttyrec para monitorizacion de sessiones, rkhunter para comprobación de rootkits \n"

##aptitude install tripwire ttyrec logrotate rkhunter

#Configuración de TTYREC
echo "TTYREC es  un shell script que permite grabación de sesiones de terminal"
read -p "Introduzca un directorio donde desa que se guarden las grabaciones de las sessiónes ssh " dirgrab

#Creamos un primer fichero de grabación y el diretorio donde se van a guardar las grabaciones
mkdir -p /usr/share/audit/$dirgrab
##ttyrec -u /root/audit/archivotest
chmod -R o+w /usr/share/audit/*

#Creamos el script que grabará las sesiones en /etc/profile.d
cat > /etc/profile.d/ttyrec.sh  <<EOF

if [ "/usr/share/audit/archivotest 'id -u' " != 0 ]
then
TTYFORMAT="/usr/share/audit/$dirgrab/\.${LOGNAME}\${HOSTNAME}\$(date +.%d·%h·%Y·%H:%M).rec"
ttyrec -u \$TTYFORMAT
fi

EOF


#Configuración de  Trypwire



