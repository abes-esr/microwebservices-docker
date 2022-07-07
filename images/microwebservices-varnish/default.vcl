vcl 4.1;


backend default {
    .host = "microwebservices-api:8080";
    
    # pour permettre de télécharger les fichiers KBART qui prennent 
    # plus de 10 minutes à se générer (10m = 600s), on règle le timeout
    # sur 900s (15 minutes)
    .first_byte_timeout = 900s;
}

sub vcl_recv {

    if (req.method != "GET" && req.method != "HEAD" && req.method != "PURGE") {
        return (pass);
    }
    # pour permettre de vider le cache si besoin sur une URL particulière
    if (req.method == "PURGE") {
        return (purge);
    }
      
    # on met en cache toutes les URL des microwebservices
    if (req.url ~ "/MicroWebServices/.+") {
      	return(hash);
    }

    return(pass);
}


sub vcl_backend_response {
    if (bereq.method != "GET" && bereq.method != "HEAD" && bereq.method != "PURGE") {
        set beresp.uncacheable = true;
        set beresp.ttl = 120s;
        return (deliver);
    }


    # ne met pas en cache si la réponse HTTP n'est pas un code 200 (succès)
    if (beresp.status != 200) {
        set beresp.ttl = 120s;
        set beresp.uncacheable = true;
        return (deliver);
    }
    
    # met en cache le <ppn>.xml
    # exemple d'URL : /MicroWebServices/?servicekey=biblio&ppn=145561143&format=application/xml
    if (bereq.url ~ "^/MicroWebServices/\?servicekey=biblio&.+") {
        unset beresp.http.Set-Cookie;
        set beresp.ttl = 10s;  # en cache pour 10 secondes
        set beresp.grace = 10s;
        return (deliver);
    }

    # met en cache les packages bacon datés
    # exemple d'URL : /MicroWebServices/?servicekey=bacon_pck2kbart&para1=JSTOR_COUPERIN_IRELAND_2019-04-11&para2=JSTOR_COUPERIN_IRELAND_2019-04-11&para3=JSTOR_COUPERIN_IRELAND_2019-04-11&format=application/vnd.ms-excel
    if (bereq.url ~ "^/MicroWebServices/\?servicekey=bacon_pck2kbart&para1=[A-Z_-]+_[0-9]{4}") {
        unset beresp.http.Set-Cookie;
        set beresp.ttl = 300d;  # en cache pour 300 jours
        set beresp.grace = 300d;
        return(deliver);
    }

    # met en cache les packages bacon non datés
    # le cache doit être plus court (24h) tant que le PURGE n'est pas implémenté dans cerclesbacon
    # exemple d'URL : /MicroWebServices/?servicekey=bacon_pck2kbart&para1=JSTOR_COUPERIN_IRELAND&para2=JSTOR_COUPERIN_IRELAND&para3=JSTOR_COUPERIN_IRELAND&format=application/vnd.ms-excel
    if (bereq.url ~ "^/MicroWebServices/\?servicekey=bacon_pck2kbart&para1=[A-Z_-]") {
        unset beresp.http.Set-Cookie;
        set beresp.ttl = 24h;  # en cache pour 24h
        set beresp.grace = 24h;
        return(deliver);
    }

    # tout le reste n'est pas mis en cache
    set beresp.ttl = 120s;
    set beresp.uncacheable = true;
    return (deliver);
}

sub vcl_deliver {

    # Pour le debug, affiche dans les header en réponse HIT (si la page vient du cache)
    # et MISS si la page ne vient pas du cache (donc vient du backend)
    if (obj.hits > 0) {
        set resp.http.X-Cache-Status = "HIT";
    } else {
        set resp.http.X-Cache-Status = "MISS";
    }

}

sub vcl_hash {
    # Purpose: Split cache by HTTP and HTTPS protocol.
    hash_data(req.http.X-Forwarded-Proto);
}

