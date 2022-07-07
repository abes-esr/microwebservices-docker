FROM httpd:2.4.52

RUN sed -i \
        -e 's/^#\(LoadModule .*mod_proxy.so\)/\1/' \
        -e 's/^#\(LoadModule .*mod_proxy_http.so\)/\1/' \
        -e 's/^#\(LoadModule .*mod_cache.so\)/\1/' \
        -e 's/^#\(LoadModule .*mod_cache_disk.so\)/\1/' \
        -e 's/^#\(LoadModule .*mod_expires.so\)/\1/' \
        -e 's/^#\(LoadModule .*mod_headers.so\)/\1/' \
        conf/httpd.conf

RUN mkdir -p /var/cache/apache/ && chmod -R 777 /var/cache/apache/

COPY ./httpd-site.conf /tmp/httpd-site.conf
RUN cat /tmp/httpd-site.conf >> conf/httpd.conf


# todo lancer htcacheclean periodiquement pour vider le cache expiré
