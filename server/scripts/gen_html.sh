#!/bin/bash

STORAGE_DIR="html/server_storage"
mkdir -p "$STORAGE_DIR"

HTTP_SERVER_PORT=9000

SVG_WIDTH="900"
SVG_HEIGHT="720"

MACHINES=$(jq -r '.machines[]' json/config.json)

MACHINES_LIST=""
TOTAL_MACHINE=0
LAST_CERT=$(./scripts/cert.sh)
ALERTE_LOG=""

#creation du menu déroulant avec le nom des machines 
for ip in $MACHINES; do
  machine_name=$(curl ${ip}:${HTTP_SERVER_PORT}/hostname/hostname)
  MACHINES_LIST="$MACHINES_LIST <a href='${machine_name}.html' class='w3-bar-item w3-button'>$machine_name</a>"
  TOTAL_MACHINE=$(($TOTAL_MACHINE + 1))
  ALERTE_LOG="$ALERTE_LOG $(curl ${ip}:${HTTP_SERVER_PORT}/detection/log)"
done

ALERTE_LOG=$(echo "$ALERTE_LOG" | sed 's/;/<br>/g')

# Fonction pour créer une page HTML d'informations sur une machine
create_html_page() {
  local name=$1  # Paramètre : nom pour la page HTML
  local filename="${name}.html"  # Nom du fichier HTML
  local foldername="$STORAGE_DIR/$name"

  #lecture des graphs pour les encoder en dur dans la page html
  svg="html/server_storage/$name/svg/total_procs.svg"
  svg_total_procs=$(cat "$svg")
  svg="html/server_storage/$name/svg/total_users_connected.svg"
  svg_total_users_connected=$(cat "$svg")
  svg="html/server_storage/$name/svg/total_ports_used.svg"
  svg_total_ports_used=$(cat "$svg")
  svg="html/server_storage/$name/svg/hardware_usage.svg"
  svg_hardware_usage=$(cat "$svg")

  # Contenu de la page HTML pour afficher le données sur la machine
  cat <<EOL > "html/$filename"
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <title>Page avec Navigation</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <!-- W3.CSS -->
  <link rel="stylesheet" href="https://www.w3schools.com/w3css/4/w3.css">
</head>
<body>

<!-- Barre de navigation -->
<div class="w3-bar w3-dark-grey w3-large">
  <a href="index.html" class="w3-bar-item w3-button">Home</a>

  <!-- Menu déroulant -->
  <div class="w3-dropdown-hover">
    <button class="w3-button">🖥️ Liste des machines</button>
    <div class="w3-dropdown-content w3-bar-block w3-card-4">
      $MACHINES_LIST
    </div>
  </div>
</div>

<!-- Contenu principal -->
<div class="w3-container w3-padding-32">
  <h1>Machine: $name</h1>
  <p>Vous trouverez ici toutes les résultats des sondes sur la machine $name</p>
  <div class="w3-row">
    <div class="w3-half">
      $svg_hardware_usage
    </div>
    <div class="w3-half">
      $svg_total_ports_used
    </div>
  </div>
  <div class="w3-row">
    <div class="w3-half">
      $svg_total_procs
    </div>
    <div class="w3-half">
      $svg_total_users_connected
    </div>
  </div>
</div>
</body>
</html>
EOL
}

cat <<EOL > "html/index.html"
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <title>Page avec Navigation</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <!-- W3.CSS -->
  <link rel="stylesheet" href="https://www.w3schools.com/w3css/4/w3.css">
</head>
<body>

<!-- Barre de navigation -->
<div class="w3-bar w3-dark-grey w3-large">
  <a href="index.html" class="w3-bar-item w3-button">Home</a>

  <!-- Menu déroulant -->
  <div class="w3-dropdown-hover">
    <button class="w3-button">Liste des machines</button>
    <div class="w3-dropdown-content w3-bar-block w3-card-4">
      $MACHINES_LIST
    </div>
  </div>
</div>

<!-- Contenu principal -->
<div class="w3-container w3-padding-32">
  <h1 class="w3-border-bottom">Page d'administration de system information</h1>
  <h3 class="w3-border-bottom">Dernière CERT</h3>
  <p>Titre: $(echo $LAST_CERT | jq -r '.title')</p>
  <p>Reference: $(echo $LAST_CERT | jq -r '.reference')</p>
  <p>Dernière date de révision: $(echo $LAST_CERT | jq -r '.last_revision_date')</p>
  <h3 class="w3-border-bottom">Liste des machines ($TOTAL_MACHINE)</h3>
  $MACHINES_LIST
  <h3 class="w3-border-bottom">Logs des alertes</h3>
  $ALERTE_LOG
</body>
</html>
EOL

# Parcourir chaque adresse IP dans la liste pour récupéré les infos de la machine
for ip in $MACHINES; do
  echo "Machine : $ip"
  machine_name=$(curl ${ip}:${HTTP_SERVER_PORT}/hostname/hostname)
  DEST="$STORAGE_DIR/$machine_name"
  mkdir -p "$DEST"

  # Télécharger récursivement les fichiers depuis le mini-serveur HTTP du client
  wget -r -np -nH --cut-dirs=0 -P "$DEST" "$ip:9000"
  
  create_html_page $machine_name
done

