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

variable "contact" {
  description = "Primary contact for this deployment"
  type        = string
  default     = "admin.devops@keykocorp.ztm"
}

variable "ecr_nginx_img_uri" {
  type        = string
  description = "ecr repo uri for the proxy image"
}

variable "ecr_api_img_uri" {
  type        = string
  description = "ecr repo uri for the api image"
}

variable "db_username" {
  description = "The username for the RDS database"
}

variable "db_password" {
  description = "The password for the RDS database"
  type        = string
  sensitive   = true
}

variable "django_secret_key" {
  description = "the key to securing signed data"
  type        = string
  # N.B. it is vital you keep this key secure, or attackers could use it to generate their own signed values.
  # https://docs.djangoproject.com/en/5.2/topics/signing/
  sensitive = true
}
