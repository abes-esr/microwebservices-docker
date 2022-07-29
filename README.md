# microwebservices-docker

L'application MicroWebServices (cf son [code source (non ouvert)](https://git.abes.fr/depots/MicroWebServices.git)) met à disposition des réseaux de l'Abes des [API permettant de rechercher et récupérer les données du Sudoc](https://api.gouv.fr/les-api/api-sudoc) via un pogramme informatique. 

Ce dépôt a comme objectif de permettre le déploiement Docker des microwebservices en l'associant à un système de cache basé sur le logiciel Varnish (dans un premier temps dédié aux besoins BACON).

Exemples d'API mises à disposition par les microwebservices :
  - https://bacon.abes.fr/package2kbart/JSTOR_COUPERIN_ARTS-AND-SCIENCES-VIII : permet de récupérer le KBART (fichier tsv) du package/bouquet JSTOR_COUPERIN_ARTS-AND-SCIENCES-VIII
  - https://www.sudoc.fr/145561143.xml : permet de récupérer la notice dont le PPN est 145561143 au format XML (cette URL ne passe pas encore par le système de cache à la date du 27/07/2022)

## Prérequis

Le code source des MicroWebService n'est pas ouvert. Ce dépôt n'est donc utilisable que par les agents de l'Abes sous VPN.
Si vous êtes en local il faut donc lancez son VPN car la phase de compilation aura besoin d'accès à https://articaftory.abes.fr et la phase de déploiement/exécution aura besoin d'accès à Oracle.

## Installation de l'application

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
L'image docker nommée `microwebservices-api:0.0.1-SNAPSHOT` sera alors construite et contiendra `MicroWebServices.war` et un serveur tomcat9 prêt à l'emploi (cf section déploiement).

## Déploiement de l'application

Une fois la compilation de l'image docker terminée (cf section précédente) lancez ceci dans un terminal :
```bash
cd /opt/pod/microwebservices-docker/
docker-compose up -d
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

```bash
# pour visualiser les logs de l'appli
cd /opt/pod/microwebservices-docker/
docker-compose logs -f --tail=100
```

Cela va afficher les 100 dernière lignes de logs générées par l'application et toutes les suivantes jusqu'au CTRL+C qui stoppera l'affichage temps réel des logs.

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

L'unique éléments à sauvegarder est le suivant (mais ce dernier est très facile à régénérer en partant de ``.env-dist``, cf section installation):
- ``/opt/pod/microwebservices-docker/.env`` : contient la configuration spécifique de notre déploiement

Le contenu du répertoire ``/opt/pod/microwebservices-docker/volumes/microwebservices-varnish/`` n'a pas besoin d'être sauvegardé. Et au contraire il est judicieux de l'exclure du système de sauvegarde car sa taille peut être grande (50Go).

## Tester l'application

Ouvrez votre navigateur Web ou lancez un cURL sur les URL locale, par exemple : 
- Pour le `<ppn>.xml` :  
  http://127.0.0.1:12081/MicroWebServices/?servicekey=biblio&ppn=145561143&format=application/xml
- Pour un petit fichier KBART daté :
  http://127.0.0.1:12081/MicroWebServices/?servicekey=bacon_pck2kbart&para1=JSTOR_COUPERIN_IRELAND_2019-04-11&para2=JSTOR_COUPERIN_IRELAND_2019-04-11&para3=JSTOR_COUPERIN_IRELAND_2019-04-11&format=application/vnd.ms-excel
- Pour un autre petit fichier KBART :  
  http://127.0.0.1:12081/MicroWebServices/?servicekey=bacon_pck2kbart&para1=JSTOR_COUPERIN_ARTS-AND-SCIENCES-VIII_2021-12-14&para2=JSTOR_COUPERIN_ARTS-AND-SCIENCES-VIII_2021-12-14&para3=JSTOR_COUPERIN_ARTS-AND-SCIENCES-VIII_2021-12-14&format=application/vnd.ms-excel
- Pour le téléchargement d'un très gros KBART (150Mo de taille et 10 minutes pour le générer) :  
  http://127.0.0.1:12081/MicroWebServices/?servicekey=bacon_pck2kbart&para1=LN_FRANCE_ALLTITLES-PFEDITEUR_2022-01-01&para2=LN_FRANCE_ALLTITLES-PFEDITEUR_2022-01-01&para3=LN_FRANCE_ALLTITLES-PFEDITEUR_2022-01-01&format=application/vnd.ms-excel
  - Remarque : ce meme fichier peut être téléchargé depuis son URL publique ici :  
    https://bacon.abes.fr/package2kbart/LN_FRANCE_ALLEBOOKS-PFEDITEUR_2022-01-01
- Pour télécharger le RSS de BACON :
  http://127.0.0.1:12081/MicroWebServices/?servicekey=bacon_rss&format=application/xml

Les mêmes URL sur l'environnement de dev (diplotaxis-dev pour les URL internes) :
- https://bacon-dev.abes.fr/package2kbart/JSTOR_COUPERIN_ARTS-AND-SCIENCES-VIII
- https://bacon-dev.abes.fr/package2kbart/LN_FRANCE_ALLEBOOKS-PFEDITEUR (attention, gros KBART de 180Mo)
- http://diplotaxis-dev.v212.abes.fr:12081/MicroWebServices/?servicekey=bacon_pck2kbart&para1=JSTOR_COUPERIN_IRELAND_2019-04-11&para2=JSTOR_COUPERIN_IRELAND_2019-04-11&para3=JSTOR_COUPERIN_IRELAND_2019-04-11&format=application/vnd.ms-excel
- http://diplotaxis-dev.v212.abes.fr:12081/MicroWebServices/?servicekey=bacon_pck2kbart&para1=JSTOR_COUPERIN_ARTS-AND-SCIENCES-VIII_2021-12-14&para2=JSTOR_COUPERIN_ARTS-AND-SCIENCES-VIII_2021-12-14&para3=JSTOR_COUPERIN_ARTS-AND-SCIENCES-VIII_2021-12-14&format=application/vnd.ms-excel
- http://diplotaxis-dev.v212.abes.fr:12081/MicroWebServices/?servicekey=bacon_rss&format=application/xml
- http://diplotaxis-dev.v212.abes.fr:12081/MicroWebServices/?servicekey=biblio&ppn=145561143&format=application/xml

Les mêmes URL sur l'environnement de test (diplotaxis-test pour les URL internes) :
- https://bacon-test.abes.fr/package2kbart/JSTOR_COUPERIN_ARTS-AND-SCIENCES-VIII
- https://bacon-test.abes.fr/package2kbart/LN_FRANCE_ALLEBOOKS-PFEDITEUR (attention, gros KBART de 180Mo)
- http://diplotaxis-test.v202.abes.fr:12081/MicroWebServices/?servicekey=bacon_pck2kbart&para1=JSTOR_COUPERIN_IRELAND_2019-04-11&para2=JSTOR_COUPERIN_IRELAND_2019-04-11&para3=JSTOR_COUPERIN_IRELAND_2019-04-11&format=application/vnd.ms-excel
- http://diplotaxis-test.v202.abes.fr:12081/MicroWebServices/?servicekey=bacon_pck2kbart&para1=JSTOR_COUPERIN_ARTS-AND-SCIENCES-VIII_2021-12-14&para2=JSTOR_COUPERIN_ARTS-AND-SCIENCES-VIII_2021-12-14&para3=JSTOR_COUPERIN_ARTS-AND-SCIENCES-VIII_2021-12-14&format=application/vnd.ms-excel
- http://diplotaxis-test.v202.abes.fr:12081/MicroWebServices/?servicekey=bacon_rss&format=application/xml
- http://diplotaxis-test.v202.abes.fr:12081/MicroWebServices/?servicekey=biblio&ppn=145561143&format=application/xml


Pour ne pas utiliser la mise en cache sur ces URL, conservez exactement les mêmes URL et remplacez le port 12081 par **12080** (cela appelera directement le conteneur ``microwebservice-api`` sans mise en cache)

Exemple pour vider le cache Varnish sur une URL précise :
```
curl -X PURGE -v "http://127.0.0.1:12081/MicroWebServices/?servicekey=biblio&ppn=145561143&format=application/xml"
curl -X PURGE -v "http://127.0.0.1:12081/MicroWebServices/?servicekey=bacon_pck2kbart&para1=JSTOR_COUPERIN_IRELAND_2019-04-11&para2=JSTOR_COUPERIN_IRELAND_2019-04-11&para3=JSTOR_COUPERIN_IRELAND_2019-04-11&format=application/vnd.ms-excel"
```

Pour afficher des logs de debug du système de cache varnish, une fois que l'application est lancée, on peut utiliser cette commande :
```
 docker exec -it microwebservices-varnish varnishlog
```


## Architecture

<img src="https://docs.google.com/drawings/d/e/2PACX-1vRwJzkixj2QSGXnGf4JdIaXOSpnsSyMznShoqJLXl9sX_5ewKdqlYIzjFcmobCYPsFOo_z5UfnlEGG6/pub?w=1319&amp;h=635">

(cf le [lien](https://docs.google.com/drawings/d/1BDwRgBFFtrGaaV31hevRFTcOMNNiOo4AhkPhbxxz9-8/edit) pour éditer le schéma)

A noter que la brique ``microwebservices-varnish`` met en cache les retours des requêtes HTTP de ``microwebservices-api`` en fonction de [critères dans l'URL](https://github.com/abes-esr/microwebservices-docker/blob/develop/images/microwebservices-varnish/default.vcl#L21-L30).

## Benchmark

Voir le [document dédié aux benchmarks](./BENCHMARK.md).
