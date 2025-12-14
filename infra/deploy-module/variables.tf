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
