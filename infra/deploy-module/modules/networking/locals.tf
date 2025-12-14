# locals {
#   azs = slice(data.aws_availability_zones.available.names, 0, length(var.public_subnets))
# }

locals {
  selected_azs = slice(var.azs, 0, length(var.public_subnets))
}
