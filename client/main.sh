#!/bin/bash

#temps maximum d'une log par défault, en minute
max_time=$((60 * 24 * 7))

#taille max du dossier, en octets
max_size=$((2000000000))

#check des flags
while getopts "ts:" flag; do
 case $flag in
   t)
   if [[ "$OPTARG" =~ ^-?[0-9]+$ ]]; then
     max_time=$OPTARG
   else
     echo "-t max time doit être un entier"
     exit 1
   fi
   ;;
   s)
   if [[ "$OPTARG" =~ ^-?[0-9]+$ ]]; then
     max_size=$OPTARG
   else
     echo "-s max size doit être un entier"
     exit 1
   fi
   ;;
   \?)
   # Handle invalid options
   ;;
 esac
done

#creation du dossier de stockage des logs
mkdir -p /var/log/sys_info/
echo "Lancement de chaque sonde(s)"

time=$(date +"%Y-%m-%d_%H-%M-%S")
data=""
cpt=0

#les sondes renvoie une liste sous forme  json
#on fine le formatage json dans la boucle pour faire
#un fichier de log json avec toutes les sondes
for sonde in $(ls sondes); do
    echo "Sonde : ${sonde}"

    #recupération du type de sonde et de son nom
    extension="${sonde##*.}"
    name="${sonde%.*}"

    #si première sonde alors "{"
    if (( $cpt == 0 ));then
      data+="{"
    else #sinon "," pour séparer de la sonde précédente
      data+=","
    fi

    if [ "$extension" == "py" ]; then #sonde python
      data+=$(python3 sondes/${sonde})
    elif [ "$extension" == "sh" ]; then #sonde bash
      data+=$(bash sondes/${sonde})
    else 
      echo "Erreur: la sonde est invalide"
      exit 1
    fi

    cpt=$(($cpt + 1))
done
      
#fermeture du formatage json
data+="}"

#on range tous dans les log en .json
#jq finalise le formataage est certifi que les données sont lisibles en json
echo $data | jq . > /var/log/sys_info/log_${time}.json

echo "Log in: /var/log/sys_info/log_${time}.json"

#check de la taille du dossier de log 
while [[ $(du -sb /var/log/sys_info | cut -f1) -gt $max_size ]]
do
  #trouvé le fichier de log le plus vieux et le supprimer
  old=$(find /var/log/sys_info -mindepth 1 -maxdepth 1 -type f -printf "%T@ %p\n" | sort -n | head -n 1 | cut -d ' ' -f2-)
  sudo rm ${old}
done

#check sur la date des logs
old=$(find /var/log/sys_info -mindepth 1 -maxdepth 1 -type f -printf "%T@ %p\n" | sort -n | head -n 1 | cut -d ' ' -f2-) #fichier le plus vieux
while [[ $(echo $(( ($(date +%s) - $(stat -c %Y ${old})) / 60 ))) -gt $max_time ]] #tant que le fichier le plus vieux est au dessus du temps de vie max d'une log
do 
  sudo rm ${old}
  old=$(find /var/log/sys_info -mindepth 1 -maxdepth 1 -type f -printf "%T@ %p\n" | sort -n | head -n 1 | cut -d ' ' -f2-) #fichier le plus vieux
done

#récupération de la dernière cert
last_cert=$(bash scripts/cert.sh)
name=$(echo $last_cert | jq -r '.["reference"]')

mkdir -p /var/log/sys_info/CERT/ 

echo $last_cert > "/var/log/sys_info/CERT/$name.json"

echo "Last CERT in: /var/log/sys_info/CERT/$name.json"

echo "Starting threat detection"

bash scripts/detection.sh

echo "Detection end"

echo "Generating graphs"

mkdir -p /var/log/sys_info/svg

python3 scripts/graphs.py

echo "Graphs generation end"

echo "Opening http server"

mkdir -p /var/log/sys_info/hostname
cat /etc/hostname > /var/log/sys_info/hostname/hostname
bash scripts/open_http_server.sh /var/log/sys_info

echo "Server open, goodbye !"
