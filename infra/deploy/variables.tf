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

variable "ecr_nginx_img_uri" {
  default = "014571658325.dkr.ecr.us-east-1.amazonaws.com/movies-reviews-api-nginx:latest"
}

variable "ecr_api_img_uri" {
  default = "014571658325.dkr.ecr.us-east-1.amazonaws.com/movies-reviews-api-api:latest"
}

variable "django_secret_key" {
  description = "the key to securing signed data"
  type        = string
  # N.B. it is vital you keep this key secure, or attackers could use it to generate their own signed values.
  # https://docs.djangoproject.com/en/5.2/topics/signing/
  sensitive = true
}
