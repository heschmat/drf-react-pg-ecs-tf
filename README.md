# Movies Reviews API — Deployment & Debugging Guide

This README consolidates deployment-related commands and provides context to help with debugging, maintenance, and manual operations.

---

## 🚀 Overview

The **Movies Reviews API** is a containerized Django-based application deployed on AWS using:

* **ECS (Fargate)** for container orchestration
* **ECR** for container image storage
* **RDS (PostgreSQL)** for persistent database storage
* **EFS** to store uploaded poster images
* **ALB** for HTTP routing
* **Secrets Manager** for managing sensitive environment variables

This README provides a toolbox of commands helpful for debugging deployments, inspecting containers, manipulating application data, and troubleshooting AWS resources.

---

## 🏗️ System Architecture Overview

Below is a high-level description of how the Movies Reviews API is structured and deployed.

### Architecture Diagram (ASCII)

```
                  ┌──────────────────────────┐
                  │    Client / Frontend     │
                  │   (Web / Mobile / cURL)  │
                  └────────────┬─────────────┘
                               │ HTTPS
                               ▼
                   ┌───────────────────────────┐
                   │ Application Load Balancer │
                   │          (ALB)            │
                   └──────────────┬────────────┘
                                  │
                        Routes /api/* to
                                  │
                                  ▼
                    ┌────────────────────────┐
                    │      ECS Fargate       │
                    │  movies-reviews-api    │
                    ├────────────────────────┤
                    │    Container: API      │
                    │    Container: Nginx    │
                    └──────────────┬─────────┘
                                   │
             ┌─────────────────────┴─────────────────────┐
             │                                           │
             ▼                                           ▼
 ┌────────────────────────┐                 ┌────────────────────────┐
 │      RDS PostgreSQL    │                 │          EFS           │
 │ movies_db (persistent) │                 │ Stores poster images   │
 └────────────────────────┘                 └────────────────────────┘

```

### Component Breakdown

* **ALB** routes all traffic to ECS tasks, checks target health, and exposes the public API endpoint.
* **ECS Fargate** runs the API and Nginx containers without managing servers.
* **ECR** stores Docker images for deployments.
* **RDS PostgreSQL** persists data such as users, movies, genres, and reviews.
* **EFS** stores uploaded media files (movie posters) shared across tasks.
* **Secrets Manager** securely stores credentials (DB password, Django secret key, etc.).

---

## 🐳 Working With ECR (Elastic Container Registry)

Useful commands for logging into ECR, building/pushing/pulling images, and inspecting image metadata.

```sh
aws ecr get-login-password --region us-east-1 \
  | docker login --username AWS --password-stdin 014571658325.dkr.ecr.us-east-1.amazonaws.com

# REPLACE `ECR_REPO` with the correct value
ECR_REPO=014571658325.dkr.ecr.us-east-1.amazonaws.com/movies-reviews-api-nginx # for proxy
ECR_REPO=014571658325.dkr.ecr.us-east-1.amazonaws.com/movies-reviews-api-api # for api

# To build api image or proxy/image use the corresponding `docker build` command:
docker build --no-cache -t img:latest -f Dockerfile.prod .
docker build --no-cache -t img:latest -f ./proxy/Dockerfile ./proxy

# tag and push the image to ECR repo
docker tag img:latest $ECR_REPO:latest
docker push $ECR_REPO:latest


# in case there are issues, the following commands could be of help:
docker pull $ECR_REPO:latest

docker run -it --entrypoint /bin/sh $ECR_REPO:latest

IMG_ID=<api-image-id>
docker image inspect $IMG_ID | jq '.[0].Config | {Entrypoint, Cmd}'
```

---

## 🛠️ ECS Exec & On‑Task Debugging

These commands allow you to enter a running ECS task, execute shell commands, and seed or modify application data.

```sh
# load the environmental variables (CLUSTER_NAME, ALB_DNS_NAME, ...)
source load_tf_env.sh

# run the following command to get the `TASK_ID`
aws ecs list-tasks --cluster $CLUSTER_NAME --service-name $SERVICE_NAME

# example `TASK_ID`
TASK_ID=a5179159ed344e4a900d52af75e4e87d

# verify `execute-command` is enables
aws ecs describe-tasks \
  --cluster $CLUSTER_NAME \
  --tasks $TASK_ID \
  --query "tasks[].enableExecuteCommand"

# open an interactive shell into the ECS task
aws ecs execute-command \
  --cluster $CLUSTER_NAME \
  --task $TASK_ID \
  --region us-east-1 \
  --container api \
  --interactive \
  --command "/bin/sh"
```

### Django management tasks
Now that we have an interactive shell inside the ECS task, initialize the *genres* data and create an admin user by running:
```sh
python manage.py seed_genres
python manage.py createsuperuser
```

---

## 🎬 API Usage Examples

Useful for smoke‑testing the deployed environment.

### Authenticate & Obtain Token

```sh
# get token authentication for the created user in the previous step.
curl -X POST "${ALB_DNS_NAME}/api/user/token/" \
  -H "Content-Type: application/json" \
  -d '{
        "email": "bruno@keykocorp.ztm",
        "password": "Berlin!!"
      }'
```

### Upload a Movie with Poster

```sh
# replace the token with your value:
TOKEN="d66564e2b67ce7ff1e62b4c0236089b9de67e847"
curl -L -o inception.jpg "https://i.ebayimg.com/images/g/LlUAAOSwm8VUwoRL/s-l1200.jpg"

curl -X POST "$ALB_DNS_NAME/api/movies/" \
  -H "Authorization: Token $TOKEN" \
  -F "title=Inception" \
  -F "description=A mind-bending thriller about dreams within dreams." \
  -F "release_year=2010" \
  -F "genres_ids=1" \
  -F "genres_ids=14" \
  -F "poster=@inception.jpg"
```

### Modify Movie Metadata

```sh
curl -X PATCH "$ALB_DNS_NAME/api/movies/1/" \
  -H "Authorization: Token $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ "description": "A mind-bending sci-fi thriller about dreams within dreams." }'
```

### Delete a Movie

```sh
curl -X DELETE "$ALB_DNS_NAME/api/movies/1/" \
  -H "Authorization: Token $TOKEN"
```

---

## 🗄️ Database Access (RDS PostgreSQL)

Connect to the production RDS instance either **through ECS exec** or directly.

```sh
# either:
psql $DB_CONN_STR

# or:
RDS_ENDPOINT=movies-reviews-api-default-db.civqbe66unlo.us-east-1.rds.amazonaws.com
DB_NAME=movies_db
DB_USER=adminx
psql -h $RDS_ENDPOINT -U $DB_USER -d $DB_NAME
# enter the password

```

Once connected to RDS via `psql`, run `\dt` to view the tables.
```sql
\dt

select * from core_movie;
```

---

## 📁 EFS (Elastic File System)

Uploaded poster images are stored in EFS and mounted at `/vol/web/media/posters`.

```sh
ls /vol/web/media/posters
```

### 📝 Notes

* Poster URLs follow: `ALB_DNS_NAME` + `MEDIA_URL` + `upload_to` path
* Ensure security groups allow:

  * ECS → EFS (port 2049)
  * ECS → RDS (port 5432)
* Egress rules matter, especially for EFS NFS traffic

---

## 🚢 Deployment Workflow

Here’s a simplified lifecycle of how updates reach production:

```
Local Dev → Build Docker Image → Push to ECR → ECS Service Deployment → Fargate Tasks Run New Version
```

### 1. Build & Tag Image

```
docker build -t movies-api:latest -f Dockerfile.prod .
docker tag movies-api:latest $ECR_REPO:latest
```

### 2. Push to ECR

```
docker push $ECR_REPO:latest
```

### 3. Trigger ECS Deployment

This may occur automatically via CI/CD or manually via:

```
aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --force-new-deployment
```

### 4. ALB Monitors Health

Only healthy tasks serve traffic.

---
