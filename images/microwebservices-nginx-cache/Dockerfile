FROM nginx:1.21.6

RUN mkdir -p /var/cache/nginx_cache/temp/ && chmod 777 /var/cache/nginx_cache/temp/
RUN mkdir -p /var/cache/nginx_cache/cache/ && chmod 777 /var/cache/nginx_cache/cache/

COPY ./default.conf /etc/nginx/conf.d/default.conf

