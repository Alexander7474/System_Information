# System Information

System information est un outils de surveilliance d'un park informatique de machine linux développé en bash et en python <br> 

Il permet: <br>
    -> La génération de graphiques récapitulatif sur l'utilisation hardware/software <br>
    -> D'alerter un administrateur système en cas de crise <br>
    -> De configurer les critère de crise <br> 
    -> De surveiller les processus et port ouvert pour garantir la sécurité des machines <br>
    -> La récupération des dernières CERT <br>

## Installation

L'outils foncitonne avec deux scripts: <br>
    ->le client sur les machines à surveillier <br>
    ->le server pour visualiser les données récupérés <br>

### Installation client

Installation des dépendances: <br> 
```sudo apt-get install python3 python3-pygal jq python3-psutils ssh```

Le dossier client doit être installer dans /root <br> 

Cette commande doit être ajouter dans les cronjobs root <br> 
```cd /root/client/ && ./main.sh```

L'envoie de mail nécessite un accès ssh vers un server pouvant éxécuter la commande ```mail```. <br> 
Pour cela il faut installer les clées id_rsa et id_rsa.pub dans un dossier client/.ssh_key <br> 

Les paramètres de détéction de crise peuvent être configurés dans detection_param.json dans le dossier client/json/<br>
Le mail d'envoie des crise est configuré dans config.json dans le dossier client/json/<br>

### Installation server

Installation des dépendances: <br> 
```sudo apt-get install python3 python3-pygal jq python3-psutils ssh```

Les ip des machines surveillées par le server doivent être entrées dans config.json dans le dossier server/json/ <br>

Le server se lance avec le script server.sh <br>

## Utilisation 

Après l'installation des clients et le server web lancé, l'accès se fait sur le port 8080 du server web.
