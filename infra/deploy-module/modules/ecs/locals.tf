locals {
  container_definition_proxy = [
    {
      name      = "proxy"
      image     = var.ecr_repo_uri_nginx
      essential = true
      user = "nginx"

      # N.B. When `networkMode=awsvpc`,
      # the host ports and container ports in port mappings must match.
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "APP_HOST", value = "127.0.0.1" },
        { name = "APP_PORT", value = "9000" }
      ]

      mountPoints = [
        {
          sourceVolume  = "static"
          containerPath = "/vol/static" # should match the values in `default.conf.tpl`
          readOnly      = true
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_tasks.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "proxy"
        }
      }
    }
  ]

  container_definition_api = [
    {
      name      = "api"
      image     = var.ecr_repo_uri_api
      essential = true
      #user = "django-user"

      # NOTE: the `name` should match those defined in the Django settings.py `DATABASES` section
      environment = [
        { name = "DB_HOST", value = var.db_host },
        { name = "DB_NAME", value = var.db_name },
        { name = "DB_PORT", value = "5432" },
        { name = "DB_USER", value = var.db_user },
        { name = "DB_PASS", value = var.db_password },
        { name = "SECRET_KEY", value = var.django_secret_key },
        { name = "ALLOWED_HOSTS", value = "*" },
        # { name = "APP_PORT", value = tostring(var.app_port) },
      ]

      mountPoints = [
        {
          sourceVolume  = "static"
          containerPath = "/vol/web/static"
          readOnly      = false
        },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_tasks.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "api"
        }
      }
    }
  ]

  # MERGE BOTH CONTAINERS INTO ONE LIST
  task_containers = concat(
    local.container_definition_proxy,
    local.container_definition_api,
  )
}
