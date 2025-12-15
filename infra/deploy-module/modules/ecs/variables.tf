variable "prefix" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "ecs_cluster_name" {
  type    = string
  default = "movies-ecs-cluster"
}

# subnet for ecs tasks
variable "public_subnets" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}

# variable "private_subnets" {
#   description = "List of CIDR blocks for private subnets"
#   type        = list(string)
# }

variable "private_subnets_cidrs" {
  
}

variable "allowed_sg_ids" {
  type = list(string)
}

variable "app_port" {
  type    = number
  default = 8000
}


variable "db_host" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "django_secret_key" {
  type      = string
  sensitive = true
}

variable "ecr_repo_uri_nginx" {
  type = string
}

variable "ecr_repo_uri_api" {
  type = string
}

variable "target_group_arn" {
  type = string
}

# EFS variables for media file storage ==========
variable "efs_file_system_id" {
  type = string
}

variable "efs_access_point_id" {
  type = string
}
