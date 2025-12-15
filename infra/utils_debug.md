## Useful commands

```md
╷
│ **Error: Backend configuration changed**
│ 
│ A change in the backend configuration has been detected, which may require migrating existing state.
│ 
│ If you wish to attempt automatic migration of the state, use `terraform init -migrate-state`.
│ If you wish to store the current configuration with no changes to the state, use `terraform init -reconfigure`.
```


## N.B.

Untill in the root `main.tf` you *import* the module like 
```tf
module "networking" {
  source = "./modules/networking"
  ...
}
```
TF won't be able to detect it. When you import a module, you need to run `terraform init` as well.


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



## TF

```md
resource "aws_iam_role_policy_attachment" "ecs_exec_role_policy_cloudwatch" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

data "aws_iam_policy_document" "ecs_task_assume_role_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}



```

You haven't declared the variable as output value in the module:

```sh
╷
│ Error: Unsupported attribute
│ 
│   on main.tf line 77, in module "ecs":
│   77:   public_subnets = module.networking.public_subnet_ids
│     ├────────────────
│     │ module.networking is a object
│ 
│ This object does not have an attribute named "public_subnet_ids".
```
