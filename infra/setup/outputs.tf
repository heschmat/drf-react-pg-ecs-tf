output "cd_user_access_key_id" {
  value = aws_iam_access_key.cd.id
}

output "cd_user_secret_access_key" {
  value     = aws_iam_access_key.cd.secret
  sensitive = true
}

output "ecr_api_img_uri" {
  value = aws_ecr_repository.api.repository_url
}

output "ecr_nginx_img_uri" {
  value = aws_ecr_repository.nginx.repository_url
}
