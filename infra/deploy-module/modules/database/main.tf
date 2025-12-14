resource "aws_db_subnet_group" "main" {
  name = "${var.prefix}-rds"
  # N.B. you MUST have at least two subnets in different AZs for RDS
  subnet_ids = var.private_subnets

  tags = {
    Name = "${var.prefix}-rds"
  }
}

resource "aws_security_group" "rds" {
  name   = "${var.prefix}-rds"
  vpc_id = var.vpc_id

  # Allow inbound Postgres from ECS tasks
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.allowed_sg_ids
  }

  # Default outbound allowed
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "main" {
  identifier        = "${var.prefix}-postgres" # the resource name in the aws console
  db_name           = var.db_name
  allocated_storage = 20
  storage_type      = "gp3"
  engine            = "postgres"
  # https://docs.aws.amazon.com/AmazonRDS/latest/PostgreSQLReleaseNotes/postgresql-versions.html
  # aws rds describe-db-engine-versions --default-only --engine postgres
  engine_version             = "17.6"
  auto_minor_version_upgrade = true
  instance_class             = "db.t4g.micro"
  username                   = var.db_username
  password                   = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # the followings need to change when actually in prod
  skip_final_snapshot     = true
  deletion_protection     = false
  multi_az                = false
  backup_retention_period = 0
  apply_immediately       = true

  # To enable Storage Autoscaling with instances that support the feature
  # you need to specify: max_allocated_storage > allocated_storage
  max_allocated_storage = 100

  tags = {
    Name = "${var.prefix}-postgres"
  }

}
