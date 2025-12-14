terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.22.1"
    }
  }

  backend "s3" {
    bucket               = "movies-api-tf-state"
    key                  = "deploy-key"
    region               = "us-east-1"
    encrypt              = true
    use_lockfile         = true
    workspace_key_prefix = "ws-environ"
    # e.g., s3://movies-api-tf-state/ws-environ/staging/deploy-key
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = terraform.workspace
      Project     = var.project_name
      Contact     = var.contact
      ManagedBy   = "infra/deploy-module"
    }
  }
}

# modules =============================================== #

module "networking" {
  source = "./modules/networking"
  prefix = local.label

  vpc_cidr = "10.0.0.0/16"

}

# ======================================================= #
# local values to avoid repetition
locals {
  label = "${var.project_name}-${terraform.workspace}"
}

# data sources
data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}
