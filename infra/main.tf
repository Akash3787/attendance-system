terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
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

module "database" {
  source = "./modules/database"

  name               = var.project
  private_subnet_ids = module.network.private_subnet_ids
  db_sg_id           = module.network.db_sg_id
  instance_class     = var.db_instance_class
}

# The ECR repository is created by infra/bootstrap so it survives destroys
data "aws_ecr_repository" "app" {
  name = var.ecr_repository_name
}

data "aws_caller_identity" "current" {}

# Created by infra/bootstrap; holds the Ansible playbooks
data "aws_s3_bucket" "artifacts" {
  bucket = "attendance-artifacts-${data.aws_caller_identity.current.account_id}-${var.region}"
}

module "app_secrets" {
  source = "./modules/app_secrets"

  name        = var.project
  admin_email = var.admin_email
}

module "iam" {
  source = "./modules/iam"

  name                 = var.project
  ecr_repository_arn   = data.aws_ecr_repository.app.arn
  artifacts_bucket_arn = data.aws_s3_bucket.artifacts.arn
  secret_arns = [
    module.database.secret_arn,
    module.app_secrets.secret_arn,
  ]
}

module "alb" {
  source = "./modules/alb"

  name              = var.project
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  alb_sg_id         = module.network.alb_sg_id
}

module "config_management" {
  source = "./modules/config_management"

  name               = var.project
  region             = var.region
  artifacts_bucket   = data.aws_s3_bucket.artifacts.id
  ecr_repository_url = data.aws_ecr_repository.app.repository_url
  db_secret_arn      = module.database.secret_arn
  app_secret_arn     = module.app_secrets.secret_arn
}

module "compute" {
  source = "./modules/compute"

  name                  = var.project
  region                = var.region
  subnet_ids            = module.network.public_subnet_ids
  app_sg_id             = module.network.app_sg_id
  instance_profile_name = module.iam.instance_profile_name
  target_group_arn      = module.alb.target_group_arn
  artifacts_bucket      = data.aws_s3_bucket.artifacts.id

  instance_type = var.instance_type
  min_size      = var.asg_min
  desired_size  = var.asg_desired
  max_size      = var.asg_max

  # The playbook settings file must exist before servers boot
  depends_on = [module.config_management]
}

module "monitoring" {
  source = "./modules/monitoring"

  name                 = var.project
  region               = var.region
  subnet_id            = module.network.public_subnet_ids[0]
  monitoring_sg_id     = module.network.monitoring_sg_id
  artifacts_bucket     = data.aws_s3_bucket.artifacts.id
  artifacts_bucket_arn = data.aws_s3_bucket.artifacts.arn
}
