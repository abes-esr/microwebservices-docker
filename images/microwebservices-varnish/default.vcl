vcl 4.0;

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
    # ne met pas en cache les routes qui ne sont pas avec ?servicekey=bacon_package2kbart
    # et avec un params qui contient des lettre en majuscule, des underscores et des tirets 
    # et qui se termine par une annee sur 4 chiffres, exemple JSTOR_COUPERIN_ARTS-AND-SCIENCES-VIII_2021-12-14
    if (req.url !~ "^/MicroWebServices/\?servicekey=bacon_package2kbart&params=[A-Z_-]+_[0-9]{4}") {
        return(pass);
    }
    #all except /MicroWebServices/+ should look for cache
    elseif (req.url ~ "/MicroWebServices/.+") {
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

    # met en cache uniquement les code 200 (succès)
    if (beresp.status != 200) {
        set beresp.ttl = 120s;
        set beresp.uncacheable = true;
        return (deliver);
    } else {
        unset beresp.http.Set-Cookie;
        set beresp.ttl = 300d;  # en cache pour 300 jours
        set beresp.grace = 300d;
        return (deliver);
    }

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

