#! /bin/bash

#focntion de déclenchement d'une alert 
call_alert () {
  echo "ALERT|$(cat /etc/hostname)|$(date +"%Y-%m-%d_%H-%M-%S"): $1;" >> /var/log/sys_info/detection/log
}

#fonction de déclenchement d'une crise
call_crisis () {
  echo "CRISE|$(cat /etc/hostname)|$(date +"%Y-%m-%d_%H-%M-%S"): $1;" >> /var/log/sys_info/detection/log

  #envoie du mail
  ./scripts/mailer.sh "$(cat /etc/hostname)" "Crise" "$(date +'%Y-%m-%d_%H-%M-%S')" "$1" 
}

mkdir -p /var/log/sys_info/detection/

criteria_json=$(cat json/detection_param.json)

last_log_path=$(find /var/log/sys_info -mindepth 1 -maxdepth 1 -type f -printf "%T@ %p\n" | sort -n | tail -n 1 | cut -d ' ' -f2-)
last_log_json=$(cat $last_log_path)

#listing des objets produit par la sonde port
#la sonde port ne créé pas de crise
echo $last_log_json | jq -c '.sonde_port[]' | while read -r port; do # boucle sur liste d'objet json
  port_n=$(echo "$port" | jq -r '.port')

  #parcours des ports dans la liste des alerts
  for port_alert in $(echo $criteria_json | jq -r '.alert.port[]'); do # boucle sur liste d'int json 
    if (( $port_n == $port_alert )); then 
      call_alert "le port $port_n est en cours d'utilisation"
    fi
  done
done

#listing des objets produit par la sonde processus
#les processus peuvent créé une crise 
echo $last_log_json | jq -c '.sonde_proc[]' | while read -r proc; do # boucle sur liste d'objet json
  proc_name=$(echo "$proc" | jq -r '.name')

  #parcours des processus dans la liste des alerts
  for proc_alert in $(echo $criteria_json | jq -r '.alert.proc_name[]'); do # boucle sur liste de str json 
    if [[ "$proc_name" == "$proc_alert" ]]; then 
      proc_pid=$(echo "$proc" | jq -r '.pid')
      call_alert "$proc_name, pid $proc_pid est en cours d'utilisation"
    fi
  done

  #parcours des processus dans la liste des crises
  for proc_crisis in $(echo $criteria_json | jq -r '.crisis.proc_name[]'); do # boucle sur liste de str json 
    if [[ "$proc_name" == "$proc_crisis" ]]; then 
      proc_pid=$(echo "$proc" | jq -r '.pid')
      call_crisis "$proc_name, pid $proc_pid est en cours d'utilisation"
    fi
  done
done

#pourcentage d'utilisation du hardware CPU/disk/ram
cpu_load=$(echo $last_log_json | jq -c '.sonde_sys.cpu.usage_percent')
disk_load=$(echo $last_log_json | jq -c '.sonde_sys.disk.percent')
memory_load=$(echo $last_log_json | jq -c '.sonde_sys.memory.percent')

#gestion des alertes de surcharge CPU/disk/ram ------------------------------------------
cpu_load_limit=$(echo $criteria_json | jq -r '.alert.load_limit.cpu')
memory_load_limit=$(echo $criteria_json | jq -r '.alert.load_limit.memory')
disk_load_limit=$(echo $criteria_json | jq -r '.alert.load_limit.disk')

#check load cpu
if (( $(echo "$cpu_load > $cpu_load_limit" |bc -l) ));then
  call_alert "La charge CPU sur le server $(cat /etc/hostname) est de $cpu_load > $cpu_load_limit"
fi

#check load disk
if (( $(echo "$memory_load > $memory_load_limit" |bc -l) ));then
  call_alert "Espace mémoire utilisé sur le server $(cat /etc/hostname) est de $memory_load > $memory_load_limit"
fi

#check load memeory
if (( $(echo "$disk_load > $disk_load_limit" |bc -l) ));then
  call_alert "Espace de stockage utilisé sur le server $(cat /etc/hostname) est de $disk_load > $disk_load_limit"
fi

#gestion des crise lors de surcharge CPU/disk/ram ---------------------------------------
cpu_load_limit=$(echo $criteria_json | jq -r '.crisis.load_limit.cpu')
memory_load_limit=$(echo $criteria_json | jq -r '.crisis.load_limit.memory')
disk_load_limit=$(echo $criteria_json | jq -r '.crisis.load_limit.disk')

#check load cpu
if (( $(echo "$cpu_load > $cpu_load_limit" |bc -l) ));then
  call_crisis "La charge CPU sur le server $(cat /etc/hostname) est de $cpu_load > $cpu_load_limit"
fi

#check load disk
if (( $(echo "$memory_load > $memory_load_limit" |bc -l) ));then
  call_crisis "Espace mémoire utilisé sur le server $(cat /etc/hostname) est de $memory_load > $memory_load_limit"
fi

#check load memeory
if (( $(echo "$disk_load > $disk_load_limit" |bc -l) ));then
  call_crisis "Espace de stockage utilisé sur le server $(cat /etc/hostname) est de $disk_load > $disk_load_limit"
fi

