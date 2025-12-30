variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "django_secret_key" {
  description = "Django secret key"
  type        = string
  sensitive   = true
}

variable "db" {
  description = "Database configuration"
  type = object({
    name     = string
    username = string
    password = string
  })

}

variable "ecr_uri_api" {
  type        = string
  description = "ecr repo uri for the api image"
}
