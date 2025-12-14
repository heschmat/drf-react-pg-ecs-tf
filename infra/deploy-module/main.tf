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

  azs = data.aws_availability_zones.available.names

  vpc_cidr = "10.0.0.0/16"

  public_subnets = [
    "10.0.11.0/24",
    "10.0.12.0/24",
  ]

  private_subnets = [
    "10.0.21.0/24",
    "10.0.22.0/24",
  ]

}

module "database" {
  source = "./modules/database"

  prefix = local.label

  vpc_id          = module.networking.vpc_id
  private_subnets = module.networking.private_subnet_ids

  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password
  allowed_sg_ids = [
    module.networking.private_sg_id
  ]
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
