variable "project_name" {
  default = "movies-api"
}

variable "contact" {
  default = "admin.devops@keykocorp.ztm"
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
