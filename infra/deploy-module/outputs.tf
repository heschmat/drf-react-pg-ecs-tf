output "vpc_id" {
  value = module.networking.vpc_id
}

output "alb_dns_name" {
  value = module.lb.alb_dns_name
}

output "private_subnet_ids" {
  value = module.networking.private_subnet_ids
}
