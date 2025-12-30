resource "aws_security_group" "rds" {
  name   = "${var.project_name}-rds-sg"
  vpc_id = module.vpc.vpc_id

  # Inbound from ECS tasks only
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    # security_groups = [aws_security_group.ecs.id]
    cidr_blocks     = module.vpc.private_subnets_cidr_blocks
  }

  # Outbound anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "this" {
  name        = "${var.project_name}-db-subnets"
  subnet_ids  = module.vpc.private_subnets
  description = "Private subnets for RDS"
}

# resource "aws_secretsmanager_secret" "db" {
#   name = "${var.project_name}-db-secret"
# }

# resource "aws_secretsmanager_secret_version" "db" {
#   secret_id     = aws_secretsmanager_secret.db.id
#   secret_string = jsonencode({
#     username = "django_user"
#     password = "SuperSecret123!"
#     database = "django_db"
#     host     = ""
#     port     = 5432
#   })
# }

resource "aws_db_instance" "postgres" {
  identifier                 = "${var.project_name}-postgres"
  engine                     = "postgres"
  engine_version             = "18"
  instance_class             = "db.t4g.micro"
  allocated_storage          = 20
  db_name                    = var.db.name
  username                   = var.db.username
  password                   = var.db.password
  db_subnet_group_name       = aws_db_subnet_group.this.name
  vpc_security_group_ids     = [aws_security_group.rds.id]
  skip_final_snapshot        = true
  publicly_accessible        = false
  multi_az                   = false
  auto_minor_version_upgrade = true
}
