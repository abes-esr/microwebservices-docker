# microwebservices-docker

L'application MicroWebServices (cf son [code source (non ouvert)](https://git.abes.fr/depots/MicroWebServices.git)) met à disposition des réseaux de l'Abes des API permettant de rechercher et récupérer les données du Sudoc via un pogramme informatique. 

Ce dépôt a comme objectif de permettre le déploiement Docker des microwebservices en l'associant à un système de cache basé sur le logiciel Varnish (dans un premier temps dédié aux besoins BACON).

Exemples d'API mis à disposition :
  - https://www.sudoc.fr/145561143.xml : permet de récupérer la notice dont le PPN est 145561143 au format XML.

Plus d'exemples ici : https://api.gouv.fr/les-api/api-sudoc

## Prérequis

Le code source des MicroWebService n'est pas ouvert. Ce dépôt n'est donc utilisable que par les agents de l'Abes sous VPN.
Si vous êtes en local il faut donc lancez son VPN car la phase de compilation aura besoin d'accès à https://articaftory.abes.fr et la phase de déploiement/exécution aura besoin d'accès à Oracle.

# Installation de l'application

```
mkdir -p /opt/pod/microwebservices-docker/
cd /opt/pod/microwebservices-docker/
git clone https://git.abes.fr/depots/MicroWebServices.git ./images/microwebservices-api/

cd /opt/pod/microwebservices-docker/
cp .env-dist .env
# personnaliser alors le contenu du .env
```

# Compilation de l'application

```
cd /opt/pod/microwebServices-docker/
docker-compose build
```
L'image docker nommée `microwebservices-api:0.0.1-SNAPSHOT` sera alors construite et contiendra `MicroWebServices.war` et un serveur tomcat9 prêt à l'emploi (cf section déploiement).

# Déploiement de l'application

Une fois la compilation de l'image docker terminée (cf section précédente) lancez ceci dans un terminal :
```
cd /opt/pod/microwebservices-docker/
docker-compose up -d
```

# Mise à jour de l'application

Pour mettre à jour l'application :
```
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

# Tester l'application

Ouvrez votre navigateur Web ou lancez un cURL sur les URL locale, par exemple : 
- Pour le `<ppn>.xml` :  
  http://127.0.0.1:12080/MicroWebServices/?servicekey=biblio&ppn=145561143&format=application/xml
- Pour un petit fichier KBART daté :
  http://127.0.0.1:12080/MicroWebServices/?servicekey=bacon_pck2kbart&para1=JSTOR_COUPERIN_IRELAND_2019-04-11&para2=JSTOR_COUPERIN_IRELAND_2019-04-11&para3=JSTOR_COUPERIN_IRELAND_2019-04-11&format=application/vnd.ms-excel
- Pour un autre petit fichier KBART :  
  http://127.0.0.1:12080/MicroWebServices/?servicekey=bacon_pck2kbart&para1=JSTOR_COUPERIN_ARTS-AND-SCIENCES-VIII_2021-12-14&para2=JSTOR_COUPERIN_ARTS-AND-SCIENCES-VIII_2021-12-14&para3=JSTOR_COUPERIN_ARTS-AND-SCIENCES-VIII_2021-12-14&format=application/vnd.ms-excel
- Pour le téléchargement d'un très gros KBART (150Mo de taille et 10 minutes pour le générer) :  
  http://127.0.0.1:12080/MicroWebServices/?servicekey=bacon_pck2kbart&para1=LN_FRANCE_ALLTITLES-PFEDITEUR_2022-01-01&para2=LN_FRANCE_ALLTITLES-PFEDITEUR_2022-01-01&para3=LN_FRANCE_ALLTITLES-PFEDITEUR_2022-01-01&format=application/vnd.ms-excel
  - Remarque : ce meme fichier peut être téléchargé depuis son URL publique ici :  
    https://bacon.abes.fr/package2kbart/LN_FRANCE_ALLEBOOKS-PFEDITEUR_2022-01-01
- Pour télécharger le RSS de BACON :
  http://127.0.0.1:12080/MicroWebServices/?servicekey=bacon_rss&format=application/xml

Pour utiliser la mise en cache sur ces URL, conservez exactement les mêmes URL et remplacez le port 12080 par **12081** (cache varnish)

Exemple pour vider le cache Varnish sur une URL précise :
```
curl -X PURGE -v "http://127.0.0.1:12081/MicroWebServices/?servicekey=biblio&ppn=145561143&format=application/xml"
curl -X PURGE -v "http://127.0.0.1:12081/MicroWebServices/?servicekey=bacon_pck2kbart&para1=JSTOR_COUPERIN_IRELAND_2019-04-11&para2=JSTOR_COUPERIN_IRELAND_2019-04-11&para3=JSTOR_COUPERIN_IRELAND_2019-04-11&format=application/vnd.ms-excel"
```

Pour afficher des logs de debug du système de cache varnish, une fois que l'application est lancée, on peut utiliser cette commande :
```
 docker exec -it microwebservices-varnish varnishlog
```

# Sauvegarde de l'application

Il n'est pas nécessaire de sauvegarder l'application car elle ne stock pas de données. La totalité des données de l'applications sont présentes dans la base de données Oracle.

# Architecture

<img src="https://docs.google.com/drawings/d/e/2PACX-1vRwJzkixj2QSGXnGf4JdIaXOSpnsSyMznShoqJLXl9sX_5ewKdqlYIzjFcmobCYPsFOo_z5UfnlEGG6/pub?w=1319&amp;h=635">

(cf le [lien](https://docs.google.com/drawings/d/1BDwRgBFFtrGaaV31hevRFTcOMNNiOo4AhkPhbxxz9-8/edit) pour éditer le schéma)

A noter que la brique ``microwebservices-varnish`` met en cache les retours des requêtes HTTP de ``microwebservices-api`` en fonction de [critères dans l'URL](https://github.com/abes-esr/microwebservices-docker/blob/develop/images/microwebservices-varnish/default.vcl#L21-L30).

# Benchmark

Voir le [document dédié aux benchmarks](./BENCHMARK.md).
