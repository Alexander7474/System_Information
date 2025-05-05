#!/bin/bash

sonde_name="sonde_port"

function get_open_port {
  #var de stockage format json
  open_port_json="\"$sonde_name\": ["

  # récupération des utilisateurs dans deux var distinct
  while read -r line; do
    if [[ $(echo "$line" | cut -d " " -f4) = "(LISTEN)" ]]; then
      username=$(echo "$line" | cut -d " " -f3)
      port=$(echo "$line" | cut -d " " -f1)
      service=$(echo "$line" | cut -d " " -f2)
      open_port_json+="{\"port\":$port,\"service\":\"$service\",\"username\":\"$username\"},"
    fi
  done < <(sudo lsof -i -P -n | awk 'NR>1 {split($9, a, ":"); print a[length(a)], $1, $3, $10}' | uniq)

  open_port_json="${open_port_json%,}]"
  
  echo "$open_port_json"
}

get_open_port
