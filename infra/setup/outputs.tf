output "cd_user_access_key_id" {
  value = aws_iam_access_key.cd.id
}

output "cd_user_secret_access_key" {
  value     = aws_iam_access_key.cd.secret
  sensitive = true
}
