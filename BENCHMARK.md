# Benchmark

Le but de ces benchmark est de tester les différentes configurations possibles du cache varnish dans le but
d'optimiser autant que possible les réglages pour viser deux objectifs :
- la mise en cache persistente des KBART BACON qui occupent une place importante  
  (environ 23Go pour les 23014 packages KBART à la date de juillet 2022)
- l'occupation mémoire RAM non infinie au niveau du serveur

## Test n°1

### Paramètre du test 

Date du test : juillet 2022

Test de chargement de tous les KBART (soit 23014 en juillet 2022) :
```
# réglage dans .env
BACON_MAX_URL_TO_WARM=0
```

Test avec unstorage backend de varnish de type "file" :
```yaml
VARNISH_STORAGE_BACKEND: "file,/var/lib/varnish/file-cache.bin,2G"
```
Et avec un chauffage des KBART non datés :
```yaml
BACON_URL_SED_BEFORE_WARM: 's#http://bacon.abes.fr/package2kbart/\([A-Z_\-]\+\)\(_[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\)#http://microwebservices-varnish:80/MicroWebServices/?servicekey=bacon_pck2kbart\&para1=\1\&para2=\1\&para3=\1\&format=application/vnd.ms-excel#g'
```

### Résultats du test 

```bash
$ docker exec -it microwebservices-varnish du -sh /var/lib/varnish/file-cache.bin
604M    /var/lib/varnish/file-cache.bin

$ docker stats --no-stream microwebservices-varnish
CONTAINER ID   NAME                       CPU %     MEM USAGE / LIMIT     MEM %     NET I/O           BLOCK I/O   PIDS
8431b25265ad   microwebservices-varnish   0.04%     963.8MiB / 12.38GiB   7.61%     1.72GB / 23.8GB   0B / 0B     217
```

## Test n°2

### Paramètre du test 

Date du test : juillet 2022

Test de chargement des 50 premiers KBART :
```
# réglage dans .env
BACON_MAX_URL_TO_WARM=50
```

Et avec unstorage backend de varnish de type "file" :
```yaml
environment:
  VARNISH_STORAGE_BACKEND: "file,/var/lib/varnish/file-cache.bin,2G"
```
Et avec un chauffage des KBART non datés :
```yaml
environment:
  BACON_URL_SED_BEFORE_WARM: 's#http://bacon.abes.fr/package2kbart/\([A-Z_\-]\+\)\(_[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\)#http://microwebservices-varnish:80/MicroWebServices/?servicekey=bacon_pck2kbart\&para1=\1\&para2=\1\&para3=\1\&format=application/vnd.ms-excel#g'
```

Avec un stockage des KBART dans un répertoire pour pouvoir connaitre la taille réèle des fichiers :
```yaml
volumes:
  - ./volumes/bacon-cache-warmer/:/opt/kbart/
environment:
  BACON_STORE_WARMED_TO_PATH: "/opt/kbart/"
```

### Résultats du test 

```bash
$ docker exec -it microwebservices-varnish du -sh /var/lib/varnish/file-cache.bin
33M     /var/lib/varnish/file-cache.bin

$ docker stats --no-stream microwebservices-varnish
CONTAINER ID   NAME                       CPU %     MEM USAGE / LIMIT     MEM %     NET I/O           BLOCK I/O   PIDS
80fc521448b3   microwebservices-varnish   0.03%     181.3MiB / 12.38GiB   1.43%     48.4MB / 70.1MB   0B / 0B     217

$ du -sh volumes/bacon-cache-warmer/
61M     volumes/bacon-cache-warmer/

$ wc -l volumes/bacon-cache-warmer/* | tail -1
  317400 total
```


## Test n°3

### Paramètre du test 

Date du test : juillet 2022

Test de chargement des 50 premiers KBART :
```
# réglage dans .env
BACON_MAX_URL_TO_WARM=50
```

Et avec unstorage backend de varnish de type "default" :
```yaml
environment:
  VARNISH_STORAGE_BACKEND: "default,2G"
```
Et avec un chauffage des KBART non datés :
```yaml
environment:
  BACON_URL_SED_BEFORE_WARM: 's#http://bacon.abes.fr/package2kbart/\([A-Z_\-]\+\)\(_[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\)#http://microwebservices-varnish:80/MicroWebServices/?servicekey=bacon_pck2kbart\&para1=\1\&para2=\1\&para3=\1\&format=application/vnd.ms-excel#g'
```

Avec un stockage des KBART dans un répertoire pour pouvoir connaitre la taille réèle des fichiers :
```yaml
volumes:
  - ./volumes/bacon-cache-warmer/:/opt/kbart/
environment:
  BACON_STORE_WARMED_TO_PATH: "/opt/kbart/"
```

### Résultats du test 

```bash
$ docker stats --no-stream microwebservices-varnish
CONTAINER ID   NAME                       CPU %     MEM USAGE / LIMIT     MEM %     NET I/O           BLOCK I/O   PIDS
720a98964d1e   microwebservices-varnish   0.07%     220.5MiB / 12.38GiB   1.74%     48.4MB / 66.3MB   0B / 0B     217

$ du -sh volumes/bacon-cache-warmer/
58M     volumes/bacon-cache-warmer/

$ wc -l volumes/bacon-cache-warmer/* | tail -1
  300776 total
```



## Test n°4

### Paramètre du test 

Date du test : juillet 2022

Test de chargement de tous les KBART :
```
# réglage dans .env
BACON_MAX_URL_TO_WARM=0
```

Et avec unstorage backend de varnish de type "default" :
```yaml
environment:
  VARNISH_STORAGE_BACKEND: "default,2G"
```
Et avec un chauffage des KBART non datés :
```yaml
environment:
  BACON_URL_SED_BEFORE_WARM: 's#http://bacon.abes.fr/package2kbart/\([A-Z_\-]\+\)\(_[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\)#http://microwebservices-varnish:80/MicroWebServices/?servicekey=bacon_pck2kbart\&para1=\1\&para2=\1\&para3=\1\&format=application/vnd.ms-excel#g'
```

Avec un stockage des KBART dans un répertoire pour pouvoir connaitre la taille réèle des fichiers :
```yaml
volumes:
  - ./volumes/bacon-cache-warmer/:/opt/kbart/
environment:
  BACON_STORE_WARMED_TO_PATH: "/opt/kbart/"
```

### Résultats du test 

```bash
$ docker stats --no-stream microwebservices-varnish
CONTAINER ID   NAME                       CPU %     MEM USAGE / LIMIT     MEM %     NET I/O           BLOCK I/O   PIDS
720a98964d1e   microwebservices-varnish   0.07%     1.549GiB / 12.38GiB   12.52%    1.65GB / 23.8GB   0B / 0B     217

$ du -sh volumes/bacon-cache-warmer/
23G     volumes/bacon-cache-warmer/

$ wc -l volumes/bacon-cache-warmer/* | tail -1
  100409425 total
```



## Test n°5

### Paramètre du test 

Date du test : juillet 2022

Test de chargement de tous les KBART :
```
# réglage dans .env
BACON_MAX_URL_TO_WARM=0
```

Et avec unstorage backend de varnish de type "file" et en préalouant 50Go dans le fichier sur disque :
```yaml
environment:
  VARNISH_STORAGE_BACKEND: "file,/var/lib/varnish/file-cache.bin,50G"
```
Et avec un chauffage des KBART non datés :
```yaml
environment:
  BACON_URL_SED_BEFORE_WARM: 's#http://bacon.abes.fr/package2kbart/\([A-Z_\-]\+\)\(_[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\)#http://microwebservices-varnish:80/MicroWebServices/?servicekey=bacon_pck2kbart\&para1=\1\&para2=\1\&para3=\1\&format=application/vnd.ms-excel#g'
```

Avec un stockage des KBART dans un répertoire pour pouvoir connaitre la taille réèle des fichiers :
```yaml
volumes:
  - ./volumes/bacon-cache-warmer/:/opt/kbart/
environment:
  BACON_STORE_WARMED_TO_PATH: "/opt/kbart/"
```

### Résultats du test 

Durée du test : 5h30

```bash
$ docker exec -it microwebservices-varnish du -sh /var/lib/varnish/file-cache.bin
1.2G    /var/lib/varnish/file-cache.bin

$ docker stats --no-stream microwebservices-varnish
CONTAINER ID   NAME                       CPU %     MEM USAGE / LIMIT     MEM %     NET I/O           BLOCK I/O   PIDS
ad47c1aec780   microwebservices-varnish   2.38%     642.8MiB / 12.38GiB   5.07%     1.67GB / 24.8GB   0B / 0B     217

$ du -sh volumes/bacon-cache-warmer/
23G     volumes/bacon-cache-warmer/

$ wc -l volumes/bacon-cache-warmer/* | tail -1
  100409425 total
```

## Conclusions

Le chauffage du cache des KBART non datés de BACON est une opération lourde qui prend environ 5h30 car certains KBART sont très lourds à être générés. Certains KBART prennent plus de 5 minutes (voir plus!) à être générés. La totalité des KBART occupent un espace disque de 23Go (non compressés) et ils contiennent 100M de lignes.

Une fois que les KBART sont dans le cache, ils deviennent alors disponibles instantanément (moins d'une seconde) car il ne sont plus recalculés coté ``microwebservices-api``.

Les benchmark ci-dessus ne cherchent pas à optimiser la vitesse de disponibilité ou la vitesse de chauffage du cache. Ces benchmark cherchent à trouver la meilleur configuration au niveau du système de cache varnish pour éviter que la totalité des KBART ne soient mis en mémoire car cela pourrait la surcharger (il faudrait potentiellement dédiée 23Go de RAM). Les benchmarks testent ainsi des variations au niveau des [storage backend de varnish](https://varnish-cache.org/docs/trunk/users-guide/storage-backends.html) : "default" et "file"

**La meilleur configuration trouvée** est la suivante :
```yaml
environment:
  VARNISH_STORAGE_BACKEND: "file,/var/lib/varnish/file-cache.bin,50G"
```

Elle consiste à assigner 50Go à un fichier ``file-cache.bin`` qui reste dans le conteneur ``microwebservices-varnish``. Il permet à varnish de venir stocker sur disque les données à mettre en cache (les KBART de BACON donc) pour soulager la mémoire vive. Cela ne signifie pas que varnish n'utilisera pas de RAM mais il va chercher à équilibrer le stockage entre la RAM et le disque. Les tests sur le chauffage de tous les KBART non datés montrent l'équilibrage suivant : 1.2G sur disque et 650Mo en RAM.

Note concernant la persistance des données de cache :  
A noter que si le conteneur ``microwebservices-varnish`` est redémarré ou recréé, le cache est alors complètement réinitialisé. Le fichier ``file-cache.bin`` n'est donc pas une garantie de persistence des données et il est d'ailleurs inutile de le sauvegarder. Varnish ne propose a ce jour (juillet 2022) pas de "storage backend" opensource proposant la gestion de la persistance. Après quelques recherches, il existe le module [Massive Storage Engine de Varnish](https://docs.varnish-software.com/varnish-cache-plus/features/mse/) mais ce dernier n'est pas dans la distribution opensource de Varnish.
