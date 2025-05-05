#!/bin/bash

MACHINE_NAME=$(hostname)
FOLDER="$1"
LOCAL_HTTP_PORT=9000

is_http_server_running() {
  ss -ltnp 2>/dev/null | grep -q ":$LOCAL_HTTP_PORT"
}

if [[ ! -d "$FOLDER" ]]; then
  echo "❌ Dossier introuvable : $FOLDER"
  exit 1
fi

if is_http_server_running; then
  echo "server déjà lancé"
else 
  # Lancer le serveur HTTP dans le dossier
  echo "Démarrage du serveur HTTP sur $HTTP_URL..."
  cd "$FOLDER" || exit 1
  python3 -m http.server "$LOCAL_HTTP_PORT" >/dev/null 2>&1 &
fi
