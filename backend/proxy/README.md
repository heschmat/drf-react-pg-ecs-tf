# Django + Gunicorn + Nginx + Docker Compose (Production) Setup

This README explains how the request flow works in a production-ready setup using:

* **Django** (application)
* **Gunicorn** (WSGI server)
* **Nginx** (reverse proxy)
* **PostgreSQL** (database)
* **Docker Compose** (container orchestration)

It also clarifies why some ports are exposed and others are not, and how the containers communicate internally.

---

## 📦 Architecture Overview

The system consists of three main services:

1. **Nginx** – entry point for all external requests
2. **API container** – Django application served via Gunicorn
3. **PostgreSQL** – database for the API

Nginx communicates with Gunicorn **over the internal Docker network**, while the client communicates only with Nginx.

```
Client → Host:8080 → Nginx (8000) → Gunicorn (9000) → Django → DB
```

---

## ⚙️ Request Flow (Step-by-Step)

### 1. Client sends a request

Example:

```
curl http://localhost:8080/api/movies/1
```

Port **8080** is mapped to the **Nginx container's port 8000**.

### 2. Nginx receives the request

Nginx runs inside the `nginx` container and listens on **port 8000**.
It evaluates the path:

* `/static/...` → served directly from mounted volumes
* everything else → proxied to the API container

Nginx proxies to:

```
proxy_pass http://api:9000;
```

Where:

* `api` = service name in docker-compose
* `9000` = Gunicorn port inside the API container

### 3. Gunicorn receives the request

The API container runs:

```
gunicorn --bind :9000 --workers 4 config.wsgi
```

Gunicorn receives the proxied request and forwards it to Django.

### 4. Django processes request

Django:

* authenticates the user
* matches URL routes
* queries the database
* serializes the response

### 5. Response flows back

Django → Gunicorn → Nginx → Client

---

## 🔥 Why Gunicorn Port 9000 Is *Not* Exposed

We **do not expose** Gunicorn's port because:

* external clients **must not** bypass Nginx
* Nginx handles static files, headers, SSL (if configured), and request buffering
* Gunicorn should only talk to Nginx, not the outside world

Docker Compose networking allows Nginx to reach Gunicorn internally using:

```
http://api:9000
```

This communication requires **no port publishing**, only internal networking.

---

## 🌐 Why Only Nginx Exposes a Port

In docker-compose:

```
ports:
  - 8080:8000
```

This exposes Nginx’s port **8000** to the host on **8080**.
Only Nginx needs to be reachable externally.

The API container (Gunicorn + Django) exposes **nothing** externally.

---

## 📂 Static & Media Files

Static and media files are stored in named Docker volumes:

```
static-data:/vol/web/static
media-data:/vol/web/media
```

* Django collects static files into these volumes
* Nginx serves them directly
* Both containers mount the same volumes, so files stay in sync

Nginx aliases these paths:

```
/static/static → /vol/static
/static/media → /vol/media
```

---

## 🏗️ Startup Sequence in the API Container

The API container runs `scripts/run.sh`, which:

1. Ensures volume directories exist and sets permissions
2. Switches to the unprivileged Django user
3. Runs:

   * `wait_for_db`
   * `collectstatic`
   * `migrate`
4. Starts Gunicorn on port **9000**

---

## 📘 Summary Table

| Component    | Purpose            | Port               | Exposed? | Who Can Reach It? |
| ------------ | ------------------ | ------------------ | -------- | ----------------- |
| **Nginx**    | Public entry point | 8000 (map to 8080) | **YES**  | Client → DNS/Host |
| **Gunicorn** | WSGI server        | 9000               | **NO**   | Nginx only        |
| **Django**   | Application        | via Gunicorn       | N/A      | Gunicorn          |
| **Postgres** | DB                 | 5432 (internal)    | NO       | API container     |

---

## ✔️ Key Takeaways

* Gunicorn listens on **9000**, but it's **not exposed** since Nginx communicates internally.
* Only Nginx exposes a port to the outside world.
* Static and media files are handled by Nginx from shared Docker volumes.
* Django dev server (`runserver`) exposes a port because it replaces Nginx + Gunicorn.
* In production, Django → Gunicorn → Nginx is the correct layered architecture.

---

Happy Deploying!
