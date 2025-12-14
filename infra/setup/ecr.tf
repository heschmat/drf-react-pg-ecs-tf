resource "aws_ecr_repository" "api" {
  name                 = "${var.project_name}-backend"
  image_tag_mutability = "MUTABLE"
  # this allows Terraform to delete the repo even if images exist.
  # to save costs we want to run `terraform destroy` when developin/learning.
  force_delete = true
  image_scanning_configuration {
    # turn the value to "true" in prod
    scan_on_push = var.environment == "prod"
  }
}

resource "aws_ecr_repository" "nginx" {
  name                 = "${var.project_name}-nginx"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
  image_scanning_configuration {
    scan_on_push = var.environment == "prod"
  }
}
