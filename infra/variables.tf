variable "region" {
  description = "AWS region for the whole project"
  type        = string
  default     = "ap-southeast-2"
}

variable "project" {
  description = "Name prefix used for resources"
  type        = string
  default     = "attendance"
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "db_instance_class" {
  description = "RDS instance size (use db.t3.micro if db.t4g.micro is not allowed)"
  type        = string
  default     = "db.t4g.micro"
}

variable "ecr_repository_name" {
  description = "ECR repository created by infra/bootstrap"
  type        = string
  default     = "attendance-app"
}

variable "admin_email" {
  description = "Email of the first teacher login"
  type        = string
  default     = "teacher@college.edu"
}

variable "instance_type" {
  description = "EC2 instance size for app servers"
  type        = string
  default     = "t3.micro"
}

variable "asg_min" {
  type    = number
  default = 1
}

variable "asg_desired" {
  type    = number
  default = 2
}

variable "asg_max" {
  type    = number
  default = 3
}
