# microwebservices-docker

L'application MicroWebServices (cf son [code source (non ouvert)](https://git.abes.fr/depots/MicroWebServices.git)) met à disposition des réseaux de l'Abes des [API permettant de rechercher et récupérer les données du Sudoc](https://api.gouv.fr/les-api/api-sudoc) via un pogramme informatique. 

Ce dépôt met à disposition la configuration docker 🐳 pour déployer les microwebservices en l'associant à un système de cache basé sur le logiciel Varnish (dans un premier temps dédié aux besoins BACON).

Exemples d'API mises à disposition par les microwebservices :
  - https://bacon.abes.fr/package2kbart/JSTOR_COUPERIN_ARTS-AND-SCIENCES-VIII : permet de récupérer le KBART (fichier tsv) du package/bouquet JSTOR_COUPERIN_ARTS-AND-SCIENCES-VIII
  - https://www.sudoc.fr/145561143.xml : permet de récupérer la notice dont le PPN est 145561143 au format XML (cette URL ne passe pas encore par le système de cache à la date du 27/07/2022)

## Prérequis

Le code source des MicroWebService n'est pas ouvert. Ce dépôt n'est donc utilisable que par les agents de l'Abes sous VPN.
Si vous êtes en local il faut donc lancez son VPN car la phase de compilation aura besoin d'accès à https://artifactory.abes.fr et la phase de déploiement/exécution aura besoin d'accès à Oracle.

Les prérequis logiciels sont :
- ``docker``
- ``docker-compose``

## Installation

Préparation du répertoire contenant les configuration docker, le code source des microwebservices pour son image docker, et le répertoire où sera stocké le cache :
```bash
# personnaliser /opt/pod si besoin pour déployer l'application où vous le souhaitez
cd /opt/pod/
git clone https://github.com/abes-esr/microwebservices-docker.git
# git clone git@github.com:abes-esr/microwebservices-docker.git
cd /opt/pod/microwebservices-docker/

# récupération du code source des microwebservices pour pouvoir générer son image docker
git clone https://git.abes.fr/depots/MicroWebServices.git ./images/microwebservices-api/
# git clone git@git.abes.fr:depots/MicroWebServices.git ./images/microwebservices-api/

# préparation du répertoire qui contiendra 
# le gros fichier où varnish stockera son cache
cd /opt/pod/microwebservices-docker/
mkdir -p ./volumes/microwebservices-varnish/
chmod 777 ./volumes/microwebservices-varnish/
```

Configuration docker du déploiement (cf le fichier [``.env-dist``](./.env-dist) qui contient toutes les variables personnalisables avec les explications) :
```bash
cd /opt/pod/microwebservices-docker/
cp .env-dist .env
# personnaliser alors le contenu du .env
```

## Compilation de l'application

```bash
cd /opt/pod/microwebservices-docker/
chmod +r images/microwebservices-varnish/*
chmod +x images/microwebservices-varnish/docker-varnish-entrypoint
docker-compose build
```
Les images docker suivantes seront alors créées en local :
  - `microwebservices-api:0.0.1-SNAPSHOT` : contiendra `MicroWebServices.war` et un serveur tomcat9 prêt à l'emploi
  - `microwebservices-varnish:7.0.2` : contiendra le varnish préconfiguré pour fonctionner avec les microwebservices

## Démarrage et arrêt de l'application

Une fois la compilation de l'image docker terminée (cf section précédente) lancez ceci dans un terminal pour la démarrer :
```bash
cd /opt/pod/microwebservices-docker/
docker-compose up -d
```

Et lancer ceci pour la stopper :
```bash
cd /opt/pod/microwebservices-docker/
docker-compose stop
```

## Mise à jour de l'application

Pour mettre à jour l'application :
```bash
# mise à jour de microwebservices-docker
cd /opt/pod/microwebservices-docker/
git pull

# mise à jour du code source des MicroWebServices
cd /opt/pod/microwebservices-docker/images/microwebservices-api/
git pull

# recompilation + redéploiement
cd /opt/pod/microwebservices-docker/
docker-compose build
docker-compose up -d
```

## Supervision


Pour afficher les 100 dernière lignes de logs générées par l'application et toutes les suivantes jusqu'au CTRL+C qui stoppera l'affichage temps réel des logs :
```bash
# pour visualiser les logs de l'appli
cd /opt/pod/microwebservices-docker/
docker-compose logs -f --tail=100
```

Pour consulter l'espace disque occupé par le cache de Varnish (dans cet exemple : 1,6Go sont utilisés par le cache) :
```bash
[gully@levant.abes.fr@diplotaxis-test microwebservices-docker]$ pwd
/opt/pod/microwebservices-docker
[gully@levant.abes.fr@diplotaxis-test microwebservices-docker]$ du -sh volumes/
1.6G    volumes/
```

Pour afficher les logs internes du système de cache ``microwebservice-varnish`` (peut être utile pour mieux comprendre comment le système de cache travail), une fois que le conteneur ``microwebservice-varnish`` est lancé, il suffit de lancer la commande suivante pour voir en temps réèl la consultation du cache (CTRL+C pour quitter) :
```bash
docker exec -it microwebservices-varnish varnishlog
```

## Sauvegardes

Il n'est pas nécessaire de sauvegarder l'application car elle ne stock pas de données. La totalité des données de l'applications sont présentes dans la base de données Oracle.

L'unique éléments à sauvegarder est le suivant (mais ce dernier est très facile à régénérer en partant de [``.env-dist``](./.env-dist), cf [section installation](#installation)):
- ``/opt/pod/microwebservices-docker/.env`` : contient la configuration spécifique de notre déploiement

Le contenu du répertoire ``/opt/pod/microwebservices-docker/volumes/microwebservices-varnish/`` n'a pas besoin d'être sauvegardé. Et au contraire il est judicieux de l'exclure du système de sauvegarde car sa taille peut être grande (50Go).

## Tester l'application

Les URL suivantes permettent de tester que l'application répond correctement et en particulier de tester son système de cache. A titre d'exemple, on peut observer que le package KBART ``LN_FRANCE_ALLTITLES-PFEDITEUR`` (180 000 lignes pour 180 Mo) arrive à être récupéré en environ 10 minutes sans le système de cache et arrive à être récupéré en environ **8 secondes avec le système de cache**.

Ouvrez votre navigateur Web ou lancez un cURL sur les URL locale, par exemple : 
- Pour le `<ppn>.xml` :  
  http://127.0.0.1:12081/MicroWebServices/?servicekey=biblio&ppn=145561143&format=application/xml
- Pour un petit fichier KBART daté :
  http://127.0.0.1:12081/MicroWebServices/?servicekey=bacon_pck2kbart&para1=JSTOR_COUPERIN_IRELAND_2019-04-11&para2=JSTOR_COUPERIN_IRELAND_2019-04-11&para3=JSTOR_COUPERIN_IRELAND_2019-04-11&format=application/vnd.ms-excel
- Pour un autre petit fichier KBART :  
  http://127.0.0.1:12081/MicroWebServices/?servicekey=bacon_pck2kbart&para1=JSTOR_COUPERIN_ARTS-AND-SCIENCES-VIII_2021-12-14&para2=JSTOR_COUPERIN_ARTS-AND-SCIENCES-VIII_2021-12-14&para3=JSTOR_COUPERIN_ARTS-AND-SCIENCES-VIII_2021-12-14&format=application/vnd.ms-excel
- Pour le téléchargement d'un très gros KBART (attention, gros KBART de 180Mo et 180 000 lignes qui prend 10 minutes pour être généré) :  
  http://127.0.0.1:12081/MicroWebServices/?servicekey=bacon_pck2kbart&para1=LN_FRANCE_ALLTITLES-PFEDITEUR_2022-01-01&para2=LN_FRANCE_ALLTITLES-PFEDITEUR_2022-01-01&para3=LN_FRANCE_ALLTITLES-PFEDITEUR_2022-01-01&format=application/vnd.ms-excel
  - Remarque : ce meme fichier peut être téléchargé depuis son URL publique ici :  
    https://bacon.abes.fr/package2kbart/LN_FRANCE_ALLTITLES-PFEDITEUR_2022-01-01
- Pour télécharger le RSS de BACON :  
  http://127.0.0.1:12081/MicroWebServices/?servicekey=bacon_rss&format=application/xml  
  http://127.0.0.1:12081/MicroWebServices/?servicekey=bacon_firstdate&format=application/xml
- http://127.0.0.1:12081/MicroWebServices/?servicekey=bacon_history&format=text/json&params=BNF_GLOBAL_GALLICA-ALLJOURNALS
- http://127.0.0.1:12081/MicroWebServices/?servicekey=bacon_multiversions&format=text/json
- http://127.0.0.1:12081/MicroWebServices/?servicekey=bacon_filter&format=text/json&providerid=0&labelled=0&istex=1&standardpackage=1&masterlist=1&mixte=1&monograph=1&serial=1
- http://127.0.0.1:12081/MicroWebServices/?servicekey=bacon_provider&format=text/json
- http://127.0.0.1:12081/MicroWebServices/?servicekey=bacon_list&format=text/json



Les mêmes URL sur l'environnement de dev (diplotaxis-dev pour les URL internes) :
- https://bacon-dev.abes.fr/package2kbart/JSTOR_COUPERIN_ARTS-AND-SCIENCES-VIII
- https://bacon-dev.abes.fr/package2kbart/LN_FRANCE_ALLTITLES-PFEDITEUR (attention, gros KBART de 180Mo et 180 000 lignes qui prend 10 minutes pour être généré)
- http://diplotaxis-dev.v212.abes.fr:12081/MicroWebServices/?servicekey=bacon_pck2kbart&para1=JSTOR_COUPERIN_IRELAND_2019-04-11&para2=JSTOR_COUPERIN_IRELAND_2019-04-11&para3=JSTOR_COUPERIN_IRELAND_2019-04-11&format=application/vnd.ms-excel
- http://diplotaxis-dev.v212.abes.fr:12081/MicroWebServices/?servicekey=bacon_pck2kbart&para1=JSTOR_COUPERIN_ARTS-AND-SCIENCES-VIII_2021-12-14&para2=JSTOR_COUPERIN_ARTS-AND-SCIENCES-VIII_2021-12-14&para3=JSTOR_COUPERIN_ARTS-AND-SCIENCES-VIII_2021-12-14&format=application/vnd.ms-excel
- http://diplotaxis-dev.v212.abes.fr:12081/MicroWebServices/?servicekey=bacon_rss&format=application/xml
- http://diplotaxis-dev.v212.abes.fr:12081/MicroWebServices/?servicekey=biblio&ppn=145561143&format=application/xml
- http://diplotaxis-dev.v212.abes.fr:12081/MicroWebServices/?servicekey=bacon_history&format=text/json&params=BNF_GLOBAL_GALLICA-ALLJOURNALS
- http://diplotaxis-dev.v212.abes.fr:12081/MicroWebServices/?servicekey=bacon_multiversions&format=text/json
- http://diplotaxis-dev.v212.abes.fr:12081/MicroWebServices/?servicekey=bacon_filter&format=text/json&providerid=0&labelled=0&istex=1&standardpackage=1&masterlist=1&mixte=1&monograph=1&serial=1
- http://diplotaxis-dev.v212.abes.fr:12081/MicroWebServices/?servicekey=bacon_provider&format=text/json
- http://diplotaxis-dev.v212.abes.fr:12081/MicroWebServices/?servicekey=bacon_list&format=text/json



Les mêmes URL sur l'environnement de test (diplotaxis-test pour les URL internes) :
- https://bacon-test.abes.fr/package2kbart/JSTOR_COUPERIN_ARTS-AND-SCIENCES-VIII
- https://bacon-test.abes.fr/package2kbart/LN_FRANCE_ALLTITLES-PFEDITEUR (attention, gros KBART de 180Mo et 180 000 lignes qui prend 10 minutes pour être généré)
- http://diplotaxis-test.v202.abes.fr:12081/MicroWebServices/?servicekey=bacon_pck2kbart&para1=JSTOR_COUPERIN_IRELAND_2019-04-11&para2=JSTOR_COUPERIN_IRELAND_2019-04-11&para3=JSTOR_COUPERIN_IRELAND_2019-04-11&format=application/vnd.ms-excel
- http://diplotaxis-test.v202.abes.fr:12081/MicroWebServices/?servicekey=bacon_pck2kbart&para1=JSTOR_COUPERIN_ARTS-AND-SCIENCES-VIII_2021-12-14&para2=JSTOR_COUPERIN_ARTS-AND-SCIENCES-VIII_2021-12-14&para3=JSTOR_COUPERIN_ARTS-AND-SCIENCES-VIII_2021-12-14&format=application/vnd.ms-excel
- http://diplotaxis-test.v202.abes.fr:12081/MicroWebServices/?servicekey=bacon_rss&format=application/xml
- http://diplotaxis-test.v202.abes.fr:12081/MicroWebServices/?servicekey=biblio&ppn=145561143&format=application/xml
- http://diplotaxis-test.v202.abes.fr:12081/MicroWebServices/?servicekey=bacon_history&format=text/json&params=BNF_GLOBAL_GALLICA-ALLJOURNALS
- http://diplotaxis-test.v202.abes.fr:12081/MicroWebServices/?servicekey=bacon_multiversions&format=text/json
- http://diplotaxis-test.v202.abes.fr:12081/MicroWebServices/?servicekey=bacon_filter&format=text/json&providerid=0&labelled=0&istex=1&standardpackage=1&masterlist=1&mixte=1&monograph=1&serial=1
- http://diplotaxis-test.v202.abes.fr:12081/MicroWebServices/?servicekey=bacon_provider&format=text/json
- http://diplotaxis-test.v202.abes.fr:12081/MicroWebServices/?servicekey=bacon_list&format=text/json


Pour ne pas utiliser la mise en cache sur ces URL, conservez exactement les mêmes URL et remplacez le port 12081 par **12080** (cela appelera directement le conteneur ``microwebservice-api`` sans mise en cache)


## Vider le cache

Pour vider le cache, deux façon de faire :
1) au niveau technique on peut le vider entièrement en redémarrant le conteneur `microwebservices-varnish` de cette façon :
   ```bash
   cd /opt/pod/microwebservices-docker/
   docker-compose restart microwebservices-varnish
   ```
2) au niveau technico-fonctionnel, on peut vider des éléments ciblés du cache en appelant la méthode HTTP ``PURGE`` sur des URL précises, exemple :
   ```bash
   curl -X PURGE -v "https://bacon-dev.abes.fr/package2kbart/JSTOR_COUPERIN_ARTS-AND-SCIENCES-VIII"
   ```

## Architecture

<img src="https://docs.google.com/drawings/d/e/2PACX-1vRwJzkixj2QSGXnGf4JdIaXOSpnsSyMznShoqJLXl9sX_5ewKdqlYIzjFcmobCYPsFOo_z5UfnlEGG6/pub?w=1319&amp;h=635">

(cf le [lien](https://docs.google.com/drawings/d/1BDwRgBFFtrGaaV31hevRFTcOMNNiOo4AhkPhbxxz9-8/edit) pour éditer le schéma)

A noter que la brique ``microwebservices-varnish`` met en cache les retours des requêtes HTTP de ``microwebservices-api`` en fonction de [critères dans l'URL](https://github.com/abes-esr/microwebservices-docker/blob/546d829d89463b2e9abdc2bca6e05aa92b1cb4d1/images/microwebservices-varnish/default.vcl#L47-L73).

## Benchmark

Voir le [document dédié aux benchmarks](./BENCHMARK.md).
