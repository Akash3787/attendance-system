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

module "app_secrets" {
  source = "./modules/app_secrets"

  name        = var.project
  admin_email = var.admin_email
}

module "iam" {
  source = "./modules/iam"

  name               = var.project
  ecr_repository_arn = data.aws_ecr_repository.app.arn
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

module "compute" {
  source = "./modules/compute"

  name                  = var.project
  region                = var.region
  subnet_ids            = module.network.public_subnet_ids
  app_sg_id             = module.network.app_sg_id
  instance_profile_name = module.iam.instance_profile_name
  target_group_arn      = module.alb.target_group_arn
  ecr_repository_url    = data.aws_ecr_repository.app.repository_url
  db_secret_arn         = module.database.secret_arn
  app_secret_arn        = module.app_secrets.secret_arn

  instance_type = var.instance_type
  min_size      = var.asg_min
  desired_size  = var.asg_desired
  max_size      = var.asg_max
}
