# IAM role and policy for ecs task execution (pulling images, logging, etc) ============ #
data "aws_iam_policy_document" "ecs_task_assume_role_policy" {
  # Define the assume role policy document here
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_execution_role" {
  name               = "${var.prefix}-ECSTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_exec_role" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM role and policy for ecs tasks to access other AWS services (e.g., SSM, Secrets Manager) ============ #
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.prefix}-ECSTaskRole"
  # we can define the assume role policy inline or load from a file (alternaive to data source)
  assume_role_policy = file("./modules/ecs/templates/task-trust-policy.json")
}

resource "aws_iam_policy" "ecs_task_policy" {
  name        = "${var.prefix}-ECSTaskPolicy"
  description = "ECS Task Policy for accessing other AWS services"

  policy = file("./modules/ecs/templates/task-ssm-policy.json")
}

resource "aws_iam_role_policy_attachment" "ecs_task_role" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}

# ecs cluster ============================== #
resource "aws_ecs_cluster" "main" {
  name = "${var.prefix}-ecs-cluster"

  # Enable Container Insights
  # https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContainerInsights.html
  # this will create a CloudWatch namespace called "ECS/ContainerInsights"
  # and automatically create the required IAM roles for CloudWatch to collect ECS metrics
  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.prefix}-ecs-cluster"
  }
}

# aws cloudwatch_log_group for ecs tasks
resource "aws_cloudwatch_log_group" "ecs_tasks" {
  name = "/ecs/${var.prefix}-tasks"
  # retention_in_days = 0 # keep logs forever
  retention_in_days = 1 # keep logs for 1 day only (to reduce costs during dev)

  tags = {
    Name = "${var.prefix}-ecs-tasks-log-group"
  }
}

# aws ecs task definition and service ============= #
resource "aws_ecs_task_definition" "api" {
  family                   = "${var.prefix}-api-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.ecs_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode(local.task_containers)

  # Define volumes for static files and EFS media storage =========== #
  volume {
    name = "static"
  }

  # for media files we use EFS storage
  # because media files can be large and need to persist beyond task lifecycle
  volume {
    name = "efs-media"
    efs_volume_configuration {
      file_system_id = var.efs_file_system_id
      transit_encryption = "ENABLED"

      authorization_config {
        access_point_id = var.efs_access_point_id
        iam             = "DISABLED"
      }
    }
  }

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  tags = {
    Name = "${var.prefix}-api-task-def"
  }
}

resource "aws_ecs_service" "api" {
  name            = "${var.prefix}-api-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 1

  launch_type      = "FARGATE"
  platform_version = "LATEST"

  # make sure to enable execute command
  # this requires the ecs task execution role to have the ssm permissions
  # doint so enables `aws ecs execute-command` functionality
  enable_execute_command = true

  network_configuration {
    assign_public_ip = true
    subnets          = var.public_subnets
    security_groups  = [aws_security_group.ecs_task.id]
    # security_groups = var.allowed_sg_ids
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "proxy"
    container_port   = var.app_port
  }
}

# security group for ecs tasks ================= #
resource "aws_security_group" "ecs_task" {
  name   = "${var.prefix}-ecs-task-sg"
  vpc_id = var.vpc_id

  # TEMPORARY public ingress (remove when ALB is added)
  ingress {
    description = "Public access to ECS task"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # Better:
    # cidr_blocks = ["YOUR_IP/32"]
    security_groups = var.allowed_sg_ids
  }

  # Postgres access
  egress {
    description = "ECS to RDS Postgres"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # General outbound (AWS APIs, HTTPS)
  egress {
    description = "Outbound HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 2049
    to_port   = 2049
    protocol  = "tcp"
    # cidr_blocks = var.private_subnets_cidrs
    cidr_blocks = [
    "10.0.21.0/24",
    "10.0.22.0/24",
  ]
  }

  tags = {
    Name = "${var.prefix}-ecs-task-sg"
  }
}
