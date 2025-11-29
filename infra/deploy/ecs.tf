/*
        ┌────────────────────────┐
        │      ECS Cluster       │
        │    (aws_ecs_cluster)   │
        └──────────┬─────────────┘
                   │
                   ▼
        ┌────────────────────────┐
        │      ECS Service       │
        │   (aws_ecs_service)    │
        └──────────┬─────────────┘
                   │ uses
                   ▼
        ┌────────────────────────┐
        │   ECS Task Definition  │
        │   (aws_ecs_task_def.)  │
        └──────────┬─────────────┘
                   │
        ┌──────────┴─────────────┐
        │                        │
        ▼                        ▼
┌──────────────┐        ┌───────────────────┐
│  Task Role   │        │   Execution Role  │
└──────────────┘        └───────────────────┘
                           │ (pull images, logs)
                           ▼
                  ┌───────────────────────┐
                  │  CloudWatch Log Group │
                  └───────────────────────┘


*/
resource "aws_iam_role" "ecs_execution_role" {
  name = "${local.prefix}-ecsTaskExecutionRole"

  #   assume_role_policy = jsonencode({
  #     Version = "2012-10-17"
  #     Statement = [
  #       {
  #         Effect = "Allow"
  #         Principal = {
  #           Service = "ecs-tasks.amazonaws.com"
  #         }
  #         Action = "sts:AssumeRole"
  #       }
  #     ]
  #   })
  assume_role_policy = file("./templates/ecs/task-trust-policy.json")
}

# resource "aws_iam_policy" "ecs_execution_role_policy" {
#   name   = "${local.prefix}-ecsTaskExecutionRolePolicy"
#   policy = file("./templates/ecs/ecs-task-execution-role-policy.json")
# }

# resource "aws_iam_role_policy_attachment" "ecs_execution_attach" {
#   role       = aws_iam_role.ecs_execution_role.name
#   policy_arn = aws_iam_policy.ecs_execution_role_policy.arn
# }

resource "aws_iam_role_policy_attachment" "ecs_exec_attach_managed" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


# ========================== #

resource "aws_iam_role" "ecs_task_role" {
  name               = "myAppTaskRole"
  assume_role_policy = file("./templates/ecs/task-trust-policy.json")
}

resource "aws_iam_policy" "ecs_task_policy" {
  name = "myAppTaskPermissions"

  # policy = jsonencode({
  #   Version = "2012-10-17"
  #   Statement = [
  #     {
  #       Effect   = "Allow"
  #       Action   = "sns:Publish"
  #       Resource = "arn:aws:sns:us-east-1:123456789012:MyTopic"
  #     },
  #     # {
  #     #   "Effect" : "Allow",
  #     #   "Action" : [
  #     #     "ssmmessages:CreateControlChannel",
  #     #     "ssmmessages:CreateDataChannel",
  #     #     "ssmmessages:OpenControlChannel",
  #     #     "ssmmessages:OpenDataChannel"
  #     #   ],
  #     #   "Resource" : "*"
  #     # }
  #   ]
  # })
  policy = file("./templates/ecs/task-ssm-policy.json")
}

resource "aws_iam_role_policy_attachment" "ecs_task_attach" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}

# ========================== #

resource "aws_ecs_cluster" "main" {
  name = "${local.prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${local.prefix}-cluster"
  }
}

# ========================== #

resource "aws_cloudwatch_log_group" "ecs_task_logs" {
  name              = "${local.prefix}-api-logs"
  retention_in_days = 1
  tags = {
    Name = "${local.prefix}-api-logs"
  }
}

# ========================== #

resource "aws_security_group" "ecs_tasks" {
  name        = "${local.prefix}-ecs-tasks-sg"
  description = "Access rules for the ECS service"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    description = "Allow inbound HTTP traffic"

    # cidr_blocks = ["0.0.0.0/0"] # for now, publically available on the internet.

    # security_groups = [aws_security_group.private_sg.id] ## ?
    security_groups = [aws_security_group.alb.id] # only accessible via alb
    # Q: does it mean if you get access of load balancer, you can access ecs task?
  }

  egress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    cidr_blocks = [
      aws_subnet.private_1.cidr_block,
      aws_subnet.private_2.cidr_block,
    ]
    description = "Allow outbound Postgres traffic to RDS"
  }

  # allow outbound HTTPS for ECR, STS, etc.
  # if not present, you'll get
  # Reason: ResourceInitializationError: unable to pull secrets or registry auth:
  ##The task cannot pull registry auth from Amazon ECR: There is a connection issue between the task and Amazon ECR.
  egress {
    description = "Allow outbound HTTPS (ECR, STS, S3 etc.)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # NFS port for EFS volumes
  egress {
    from_port = 2049
    to_port = 2049
    protocol = "tcp"
    cidr_blocks = [
      aws_subnet.private_1.cidr_block,
      aws_subnet.private_2.cidr_block,
    ]
  }

}

# ========================== #
resource "aws_ecs_task_definition" "api" {
  family = "${local.prefix}-api-task"

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc" # required for Fargate. Gives each task its own ENI (IP address).

  cpu    = 512
  memory = 1024

  # allows ECS to pull images from ECR & write logs to CloudWatch.
  execution_role_arn = aws_iam_role.ecs_execution_role.arn
  # define the IAM permissions that containers inside the task can use.
  task_role_arn = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode(local.task_containers)

  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition#volume
  # N.B. No host path means an empty ephemeral volume stored in the Fargate task.
  volume {
    name = "static"
  }

  volume {
    name = "efs-media"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.media.id
      transit_encryption = "ENABLED"

      authorization_config {
        access_point_id = aws_efs_access_point.media_ap.id
        iam = "DISABLED"
      }
    }
  }

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  tags = {
    Name = "${local.prefix}-api-task"
  }
}

# ========================== #

resource "aws_ecs_service" "api" {
  name            = "${local.prefix}-api"
  cluster         = aws_ecs_cluster.main.name
  task_definition = aws_ecs_task_definition.api.family
  desired_count   = 1

  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/platform-fargate.html
  launch_type = "FARGATE"
  # platform_version = "1.4.0"
  platform_version = "LATEST"

  enable_execute_command = true

  network_configuration {
    # # FOR TEST ONLY: allow public access
    # assign_public_ip = true

    # subnets = [
    #   aws_subnet.public_1.id,
    #   aws_subnet.public_2.id
    # ]

    subnets = [
      aws_subnet.private_1.id,
      aws_subnet.private_2.id
    ]

    security_groups = [aws_security_group.ecs_tasks.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "proxy"
    container_port   = 8000
  }
}
