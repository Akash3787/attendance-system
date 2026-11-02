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
