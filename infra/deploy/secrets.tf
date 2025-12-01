resource "aws_secretsmanager_secret" "db_password" {
  name        = "${local.prefix}-db-password"
  description = "Database password for Django app"
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = aws_db_instance.main.password
}

resource "aws_secretsmanager_secret" "django_secret_key" {
  name        = "${local.prefix}-django-secret-key"
  description = "Django SECRET_KEY"
}

resource "aws_secretsmanager_secret_version" "django_secret_key" {
  secret_id     = aws_secretsmanager_secret.django_secret_key.id
  secret_string = var.django_secret_key
}

# IAM ============================ #
resource "aws_iam_policy" "ecs_secrets_policy" {
  name = "${local.prefix}-ecs-secrets-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.db_password.arn,
          aws_secretsmanager_secret.django_secret_key.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_secrets_attach" {
  # role       = aws_iam_role.ecs_task_role.name
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.ecs_secrets_policy.arn
}
