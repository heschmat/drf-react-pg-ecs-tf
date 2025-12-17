variable "project_name" {
  default = "movies-api"
}

variable "contact" {
  default = "admin.devops@keykocorp.ztm"
}

# networking variables ===================== #
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type = list(string)
  default = [
    "10.0.11.0/24",
    "10.0.12.0/24",
  ]
}

variable "private_subnet_cidrs" {
  type = list(string)
  default = [
    "10.0.21.0/24",
    "10.0.22.0/24",
  ]
}

# db variables ============================= #
variable "db_name" {
  default = "moviesdb"
}

variable "db_username" {
  default = "adminx"
}

variable "db_password" {
  sensitive = true
}

# ecs variables ============================ #

variable "django_secret_key" {
  sensitive = true
}

# ecr repo uris ======================= #
variable "ecr_repo_uri_nginx" {
  type = string
}

variable "ecr_repo_uri_api" {
  type = string
}
