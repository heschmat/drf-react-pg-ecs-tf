terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }

    http = {
      source  = "hashicorp/http"
      version = "~> 3.5.0"
    }
  }

  backend "s3" {
    bucket               = "movies-drf-api"
    key                  = "deploy-key"
    region               = "us-east-1"
    use_lockfile         = true
    encrypt              = true
    workspace_key_prefix = "environ-ws"
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = terraform.workspace
      ProjectName = var.project_name
      Contact     = var.contact
      ManagedBy   = "terraform/deploy"
    }
  }
}

locals {
  prefix = "${var.project_name}-${terraform.workspace}"
}

data "aws_region" "current" {}
