variable "prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnets" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}