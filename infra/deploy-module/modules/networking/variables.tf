variable "prefix" {
  type = string
}

variable "azs" {
  description = "List of availability zones to use"
  type        = list(string)
}

variable "vpc_cidr" {
  type    = string
  # default = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
}

variable "allow_http_from" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}
