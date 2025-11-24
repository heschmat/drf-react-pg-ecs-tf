#!/bin/sh

set -e

# Fix permissions for mounted volumes (must run as root)
mkdir -p /vol/web/static /vol/web/media
chown -R ${DJANGO_USER}:${DJANGO_USER} /vol/web
chmod 755 /vol/web

# Drop privileges
su ${DJANGO_USER} <<EOF
python manage.py wait_for_db
python manage.py collectstatic --noinput
python manage.py migrate
gunicorn --bind :9000 --workers 4 config.wsgi
EOF