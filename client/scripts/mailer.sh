#!/bin/bash

#param order: server_name crisis_type time message

dest_email=$(cat json/config.json | jq -r ".crisis_mail")

#application des paramètres sur le templates de mail
mail_send=$(sed -e "s/\[app_name\]/system monitor/g" \
        -e "s/\[server_name\]/$1/g" \
        -e "s/\[crisis_type\]/$2/g" \
        -e "s/\[time\]/$3/g" \
        -e "s/\[message\]/$4/g" scripts/mail.template)

#commande a éxécuté sur pedago pour envoyer le mail
mail_cmd="echo -e '$mail_send' | mail -s 'Crise system monitor' $dest_email"

#envoie du mail depuis le server pedago avec un accès ssh
ssh -i .ssh_key/id_rsa uapv2401246@pedago.univ-avignon.fr $mail_cmd
