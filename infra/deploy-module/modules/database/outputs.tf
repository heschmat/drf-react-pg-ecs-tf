output "db_host" {
  value = aws_db_instance.main.address
}

output "db_name" {
  value = aws_db_instance.main.db_name
}

output "db_user" {
  value = aws_db_instance.main.username
}

output "db_password" {
  value = var.db_password
}

output "db_port" {
  value = aws_db_instance.main.port
}