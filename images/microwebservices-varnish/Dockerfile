FROM varnish:7.1.0

# configuration varnish spécifique pour les microwebservices
COPY ./default.vcl /etc/varnish/default.vcl

# surcharge de l'entrypoint de docker pour pouvoir dire à 
# varnish d'écrire dans des fichiers plutôt que dans la mémoire
# https://github.com/varnish/docker-varnish/tree/master/fresh/debian
COPY ./docker-varnish-entrypoint /usr/local/bin/docker-varnish-entrypoint
