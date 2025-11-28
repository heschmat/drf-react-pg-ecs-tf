# @TODO
Here comes useful commands to help when debugging application deployment.

```
aws ecs execute-command \
    --cluster movies-reviews-api-default-cluster \
    --task b819bf2e16244192b0d5ffebc10a5a46 \
    --region us-east-1 \
    --container api \
    --interactive \
    --command "sh -c 'ls -l /vol'"


aws ecs describe-tasks \
    --cluster movies-reviews-api-default-cluster \
    --tasks 86817c93cf6a41ce9deb6418c8f88894 \
    --query "tasks[].enableExecuteCommand"


aws ecs execute-command \
    --cluster movies-reviews-api-default-cluster \
    --task f60361c0ecac4e54914a4a8bc552548f \
    --region us-east-1 \
    --container api \
    --interactive \
    --command "/bin/sh"



aws ecr get-login-password --region us-east-1 \
  | docker login --username AWS --password-stdin 014571658325.dkr.ecr.us-east-1.amazonaws.com

ECR_REPO=014571658325.dkr.ecr.us-east-1.amazonaws.com/movies-reviews-api-nginx
docker build --no-cache -t img:latest -f Dockerfile.prod .
docker tag img:latest $ECR_REPO_APP:latest
docker push $ECR_REPO_APP:latest

docker pull $ECR_REPO_APP:latest

docker run -it --entrypoint /bin/sh $ECR_REPO_APP:latest

IMG_ID=08fa903aae72
docker image inspect $IMG_ID | jq '.[0].Config | {Entrypoint, Cmd}'


docker build --no-cache -t img_proxy -f ./proxy/Dockerfile ./proxy



# alb:

aws elbv2 describe-target-health --target-group-arn <tg-arn>
```

