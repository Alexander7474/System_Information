#!/bin/bash

#récupération de la dèrnière cert 
last_cert=$(curl -s https://www.cert.ssi.gouv.fr/alerte/json/ | jq -r 'sort_by(.last_revision_date) | reverse | .[0]')

echo $last_cert

