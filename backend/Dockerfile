FROM python:3.13-slim
LABEL maintainer="/heschmatx"

ARG DJANGO_USER=django-user

# Prevents Python from writing .pyc files to disc
ENV PYTHONDONTWRITEBYTECODE=1
# Ensures that Python output is sent straight to terminal (e.g. your container log) without being first buffered
ENV PYTHONUNBUFFERED=1

COPY ./requirements*.txt /tmp/.
WORKDIR /code
COPY . .

# N.B. This doesn't expose. It's just documentation for users of the image.
EXPOSE 8000

ARG DEV=false
RUN pip install --upgrade pip && \
    apt-get update && apt-get install -y --no-install-recommends \
        postgresql-client \
    && \
    pip install -r /tmp/requirements.txt && \
    if [ "$DEV" = "true" ] ; then pip install -r /tmp/requirements.dev.txt ; fi && \
    # remove what's not needed anymore.
    rm -rf /var/lib/apt/lists/* /tmp && \
    useradd -M ${DJANGO_USER}

USER ${DJANGO_USER}

# Run Django development server
# CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
