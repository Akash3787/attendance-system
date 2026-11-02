terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state in the bucket created by infra/bootstrap.
  # Backend blocks cannot use variables, so the bucket name is written out.
  backend "s3" {
    bucket       = "attendance-tfstate-428032596088-ap-southeast-2"
    key          = "attendance-system/terraform.tfstate"
    region       = "ap-southeast-2"
    encrypt      = true
    use_lockfile = true # S3-native state locking (Terraform 1.10+)
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = var.project
      ManagedBy = "terraform"
    }
  }
}

module "network" {
  source = "./modules/network"

  name     = var.project
  vpc_cidr = var.vpc_cidr
}
