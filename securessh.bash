#!/bin/bash

#Este script está bajo licencia GPL y se distribuye sin garantías, copia, modifica y haz lo que quieras con él.
#Este script configura los requisitos mínimos de seguridad de un servidor SSH, creado en Ubuntu 14.04
#Creado por Kao y M 2/09/2014

echo

echo    '###############################################################################################'
echo    '#                                    SECURE SSH SCRIPT					       #'
echo    '#				  Aseguro de forma básica un servidor ssh		       #'
echo    '#					      BY  K&M					       #'
echo -e '############################################################################################### \n'

echo "Se crea una copia de la configuración actual de ssh en /root/backfiles"
mkdir /root/backfiles
cp /etc/ssh/sshd_config /root/backfiles/sshd_config.backup

#Dando Explicaciones al usuario
echo "Lo primero que hace este script es modificar el /etc/issue.net para no dar pistas sobre nuestro so"
echo "Modificando el /etc/issue.net"
cp /etc/issue.net /root/backfile
echo "Private Server Unknown Release" > /etc/issue.net

#Configurando y securizando SSH
#Recogida de Variables del usuario

#PUERTO
read -p "Introduce un puerto para ssh por encima de 1024 y por debajo de 65535:  "  puerto

#USUARIOS
echo -e  "A continuación se elegirán usuarios podrán acceder por ssh, \n "
echo   "si los usuarios elegidos no existen serán creados, el  resto de los ususarios quedarán restringidos"
read -p "Introduce el número de usuarios que deseas permitir: "  numusers

for (( i=1; i<=$numusers; i++ ))
do
        read -p "Introduce el nombre del usuario $i: " unusuario
        lospermitidos+=$unusuario" "


if  grep -qw $unusuario  /etc/passwd
 then
        echo "El usuario elegido existe. RECUERDA QUE A PARTIR DE AHORA SOLO SE LE PERMITIRÁ ACCESO A ESE USUARIO"
  else
        echo  "Se creará el usuario solicitado. RECUERDA QUE A PARTIR DE AHORA SOLO SE LE PERMITIRA ACCESO A ESE USUARIO"
        adduser $user
fi

done

#IP
echo -e "¿Deseas restringir el acceso a una sola ip o a un dominio,\n"
read -p "Si respondes si SOLO SE PERMITIRÁN USUARIOS QUE PROVENGAN DE ESA IP O DOMINIO  y todo el resto serán denegados? (s/n) " restringir

if [ $restringir = "s" ]
then
	read -p "Introduce la ip o el dominio a permitir: " ips
fi


#Configuración del fichero sshd_config por sus valores seguros
cd /etc/ssh

sed -i "s|Port .*|Port $puerto |g" sshd_config #modifica el puerto
#(si alguien gana acceso por ssh, al menos que tenga que escalar no se lo damos todo hecho)
sed -i "s|PermitRootLogin without-password|PermitRootLogin no |g" sshd_config #Impide el acceso a root
#evita scripts scripts de fuerza bruta
sed -i "s|LoginGraceTime 120|LoginGraceTime 30 |g" sshd_config #Tiempo que se mantiene abierta laconexión
sed -i "s|#MaxStartups .*|MaxStartups 3 |g" sshd_config #Nº de conexiones simultaneas maximas por usuario



#Añadiendo Variables
echo "AllowUsers $lospermitidos *@$ips" >> /etc/ssh/sshd_config #Especifica un usuario para el ssh
echo "MaxAuthTries 2" >> /etc/ssh/sshd_config #Nº Máximo de intentos permitidos = 3

service ssh reload

echo "Se ha finalizado, Gracias por utilizar este script."
