#!/bin/sh
set -e

# Ensure required directories exist
mkdir -p /vol/web/static /vol/web/media

echo "Waiting for database..."
python manage.py wait_for_db

echo "Collecting static files..."
python manage.py collectstatic --noinput

echo "Applying migrations..."
python manage.py migrate --noinput

echo "Starting gunicorn..."
# Use exec so gunicorn becomes PID 1 and stays running
exec gunicorn --bind 0.0.0.0:9000 --workers 4 config.wsgi

# # Fix permissions for mounted volumes (must run as root)
# mkdir -p /vol/web/static /vol/web/media
# chown -R ${DJANGO_USER}:${DJANGO_USER} /vol/web
# chmod 755 /vol/web

# # Drop privileges
# su ${DJANGO_USER} <<EOF
# python manage.py wait_for_db
# python manage.py collectstatic --noinput
# python manage.py migrate
# gunicorn --bind :9000 --workers 4 config.wsgi
# EOF