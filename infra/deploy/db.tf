resource "aws_db_subnet_group" "main" {
  name = "${local.prefix}-rds"
  # N.B. you MUST have at least two subnets in different AZs for RDS
  subnet_ids = [
    aws_subnet.private_1.id,
    aws_subnet.private_2.id
  ]

  tags = {
    Name = "${local.prefix}-rds"
  }
}

resource "aws_security_group" "rds" {
  name        = "${local.prefix}-rds"
  vpc_id      = aws_vpc.main.id
  description = "Allow inbound Postgres traffic from private EC2 (and ECS later)"

  ingress {
    description = "Postgres from private EC2"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [
      aws_security_group.private_ec2_sg.id, # for test
      aws_security_group.ecs_tasks.id
    ]
  }

  # Outbound allowed (normal for RDS SG)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.prefix}-rds-sg"
  }
}


resource "aws_db_instance" "main" {
  identifier        = "${local.prefix}-db" # the resource name in the aws console
  db_name           = "movies_db"
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

  skip_final_snapshot     = true
  deletion_protection     = false
  multi_az                = false
  backup_retention_period = 0
  apply_immediately       = true

  max_allocated_storage = 100

  tags = {
    Name = "${local.prefix}-rds-instance"
  }

}
