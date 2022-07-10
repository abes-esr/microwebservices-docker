# Benchmark

Le but de ces benchmark est de tester les différentes configurations possibles du cache varnish dans le but
d'optimiser autant que possible les réglages pour viser deux objectifs :
- la mise en cache persistente des KBART BACON qui occupent une place importante (environ 23Go pour les X packages KBART à la date de juillet 2022)
- l'occupation mémoire RAM non infinie au niveau du serveur

## Test n°1

### Paramètre du test 

Test de chargement de tous les KBART (soit XXX en juillet 2022):
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

Test de chargement des 50 premiers KBART :
```
# réglage dans .env
BACON_MAX_URL_TO_WARM=50
```

Et avec unstorage backend de varnish de type "file" :
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

Test de chargement de tous les KBART :
```
# réglage dans .env
BACON_MAX_URL_TO_WARM=0
```

Et avec unstorage backend de varnish de type "file" :
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