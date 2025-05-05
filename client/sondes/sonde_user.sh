#!/bin/bash

sonde_name="sonde_user"

function get_users_info {
  #var de stockage format json
  users_json="\"$sonde_name\": ["

  # on ignore l'en-tête de 'w' avec tail -n +2
  while read -r line; do
    # nettoyage espaces multiples pour découpage fiable
  clean_line=$(echo "$line" | tr -s ' ')

    # extraction des champs avec cut (basé sur des positions fixes après nettoyage)
    username=$(echo "$line" | cut -d ' ' -f1)
    tty=$(echo "$line" | cut -d ' ' -f2)
    from=$(echo "$line" | cut -d ' ' -f3)
    login_time=$(echo "$line" | cut -d ' ' -f4)
    command=$(echo "$line" | cut -d ' ' -f8-)

    users_json+="{\"username\":\"$username\",\"tty\":\"$tty\",\"from\":\"$from\",\"login_time\":\"$login_time\",\"command\":\"$command\"},"
  done < <(w -h | tr -s ' ')

  users_json="${users_json%,}]"
  
  echo "$users_json"
}


arg=0
if [[ $# -ne 1 ]]; then
  get_users_info $arg
  exit
fi 
get_users_info $1
