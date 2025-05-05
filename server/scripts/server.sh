#!/bin/bash

PORT=8080
WEBROOT="./html"  # Dossier contenant les fichiers HTML

# Démarre un serveur en boucle infinie
while true; do
  echo "Attente de connexion sur le port $PORT..."
  
  # Écoute 1 connexion à la fois
  nc -l -p "$PORT" -q 1 | while read line; do
   

    # Récupère la première ligne de la requête HTTP
    [[ "$line" =~ ^GET\ ([^?\ ]+)\ HTTP/.* ]] && path="${BASH_REMATCH[1]}"
    
    # Supprime le slash initial, ou remplace par index.html
    file="${path#/}"
    [[ -z "$file" ]] && file="index.html"
    
    fullpath="$WEBROOT/$file"

    echo "Requête pour : $file"

    if [[ $file =~ favicon ]]; then
      echo "NO FAVICON HERE"
      break 
    fi

   #éxécute le script de génération des page html 
  ./scripts/gen_html.sh

    if [[ -f "$fullpath" ]]; then
      echo "Fichier trouvé, envoi..."
      (
        echo -e "HTTP/1.1 200 OK"
        echo -e "Content-Type: text/html"
        echo -e ""
        cat "$fullpath"
      ) | nc -N -l -p "$PORT"
    else
      echo "Fichier non trouvé : $fullpath"
      (
        echo -e "HTTP/1.1 404 Not Found"
        echo -e "Content-Type: text/html"
        echo -e ""
        echo "<h1>404 - Not Found</h1><p>$file</p>"
      ) | nc -N -l -p "$PORT"
    fi

    break  # Une seule requête à la fois
  done
done
