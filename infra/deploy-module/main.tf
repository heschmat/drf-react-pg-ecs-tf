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
    # module.networking.private_sg_id
    module.ecs.ecs_task_sg_id
  ]
}

module "ecs" {
  source     = "./modules/ecs"
  prefix     = local.label
  aws_region = data.aws_region.current.id
  vpc_id     = module.networking.vpc_id

  # private_subnets = module.networking.private_subnet_ids
  private_subnets_cidrs = module.networking.private_subnet_ids
  public_subnets = module.networking.public_subnet_ids
  allowed_sg_ids = [
    # module.networking.private_sg_id
    module.lb.alb_security_group_id
  ]

  ecr_repo_uri_nginx = var.ecr_repo_uri_nginx
  ecr_repo_uri_api   = var.ecr_repo_uri_api

  db_host     = module.database.db_host
  db_name     = module.database.db_name
  db_user     = module.database.db_user
  db_password = module.database.db_password

  django_secret_key = var.django_secret_key

  target_group_arn = module.lb.api_target_group_arn

  efs_file_system_id = module.efs.file_system_id
  efs_access_point_id = module.efs.access_point_id
}

module "lb" {
  source         = "./modules/lb"
  prefix         = local.label
  vpc_id         = module.networking.vpc_id
  public_subnets = module.networking.public_subnet_ids

}

module "efs" {
  source = "./modules/efs"
  prefix = local.label
  vpc_id          = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids_map
  ecs_task_sg_id = module.ecs.ecs_task_sg_id

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
