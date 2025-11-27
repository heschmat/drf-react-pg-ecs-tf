variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "state_bucket" {
  description = "S3 bucket name used for storing Terraform state"
  type        = string
}

variable "contact" {
  description = "Primary contact for this deployment"
  type        = string
  default     = "admin.devops@keykocorp.ztm"
}

variable "db_username" {
  description = "The username for the RDS database"
  default     = "adminx"
}

variable "db_password" {
  description = "The password for the RDS database"
  type        = string
  sensitive   = true
}

output "rds_endpoint" {
  value = aws_db_instance.main.address
}

output "rds_port" {
  value = aws_db_instance.main.port
}

output "rds_db_name" {
  value = aws_db_instance.main.db_name
}

output "rds_security_group_id" {
  value = aws_security_group.rds.id
}

output "rds_connection_string" {
  value     = "postgres://${var.db_username}:${var.db_password}@${aws_db_instance.main.address}:${aws_db_instance.main.port}/${aws_db_instance.main.db_name}"
  sensitive = true
}
