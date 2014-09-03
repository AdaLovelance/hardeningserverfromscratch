#!/bin/bash

#Este script está bajo licencia GPL y se distribuye sin garantías, copia, modifica y haz lo que quieras con él.
#Este script configura rkhunter para ser alertados de posibles rootkits
#Creado en Ubuntu 14.04
#Creado por Kao y M 3/09/2014

echo

echo    '###############################################################################################'
echo    '#                                 Server Rootkits Harden        			       #'
echo    '#                            Configuro Rkhunter y Chkrootkit                                  #'
echo    '#					   BY  K&M	                                       #'
echo -e '############################################################################################### \n'
echo
echo -e "Este script securizará tu servidor, puedes ver la copia \n"
echo -e "de los ficheros modificados en /root/backupf"
sleep 3
mkdir /root/backupf

aptitude update && aptitude install rkhunter chkrootkit
echo "Rkhunter instalado ahora se actulizará, esto puede tardar unos minutos, no corte el script."
rkhunter --update
rkhunter -c --createlogfile rkhunter.lo

mv /etc/cron.weekly/rkhunter /etc/cron.weekly/rkhunter_update
mv /etc/cron.daily/rkhunter /etc/cron.weekly/rkhunter_run
mv /etc/cron.daily/chkrootkit /etc/cron.weekly/

read -p  "¿Desea scanear ahora su sistema? (s/n): " respuesta

if [ $respuesta = "s" ]
then
rkhunter -c
fi

