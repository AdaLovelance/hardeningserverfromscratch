#!/bin/bash

#Este script está bajo licencia GPL y se distribuye sin garantías, copia, modifica y haz lo que quieras con él.
#Este script graba la actividad de la shell de los usuarios y la guarda en formato .rec en un directorio oculto
#Creado en Ubuntu 14.04
#Creado por Kao y M 2/09/2014

echo

echo    '###############################################################################################'
echo    '#                                 Server Users Activity Record 			                         #'
echo    '# Grabo lo que hacen los usuarios en la shell y lo guardo en un directorio oculto en /opt     #'
echo    '#					                                 BY  K&M		                        			         #'
echo -e '############################################################################################### \n'

aptitude install ttyrec

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


