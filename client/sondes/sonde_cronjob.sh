#!/bin/bash

sonde_name="sonde_cronjob"

function get_cronjob {
  #var de stockage format json
  cronjob_json="\"$sonde_name\": ["

  # récupération des utilisateurs dans deux var distinct
  while read -r line; do
      username=$(echo "$line" | cut -d " " -f1)
      command=$(echo "$line" | cut -d " " -f2-)
      cronjob_json+="{\"username\":\"$username\",\"command\":\"$command\"},"
  done < <(cat /etc/crontab | grep -v '^#' | awk 'NF > 6 {print $6, substr($0, index($0,$7))}')

  cronjob_json="${cronjob_json%,}]"
  
  echo "$cronjob_json"
}

get_cronjob
