terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket       = "movies-api-ztm"
    key          = "setup-key"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = terraform.workspace
      ProjectName = var.project_name
      Contact     = var.contact
      ManagedBy   = "terraform/setup"
    }
  }
}

locals {
  prefix = var.project_name
}
