variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "movies-api-ztm"
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "state_bucket" {
  description = "S3 bucket name used for storing Terraform state"
  type        = string
  default     = "movies-api-ztm"
}

variable "contact" {
  description = "Primary contact for this deployment"
  type        = string
  default     = "admin.devops@keykocorp.ztm"
}

variable "environment" {
  # usecase: (ecr) scan_on_push = var.environment == "prod"
  default = "dev"
}
