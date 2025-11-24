server {
    listen ${LISTEN_PORT};

    location /static/static {
        alias /vol/static;
    }

    location /static/media {
        alias /vol/media;
    }

    location / {
        include              gunicorn_headers;
        proxy_pass           http://${APP_HOST}:${APP_PORT};
        proxy_redirect       off;
        client_max_body_size 10M;
    }
}
