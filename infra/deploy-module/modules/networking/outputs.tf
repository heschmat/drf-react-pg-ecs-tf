output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_subnet_ids" {
  value = [for s in aws_subnet.private : s.id]
}

output "public_subnet_ids" {
  value = [for s in aws_subnet.public : s.id]
}

output "private_sg_id" {
  value = aws_security_group.private.id
}

output "private_subnet_ids_map" {
  value = {
    for k, subnet in aws_subnet.private :
    k => subnet.id
  }
}
