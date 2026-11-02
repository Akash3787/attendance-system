variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "subnet_ids" {
  description = "Subnets for the app servers"
  type        = list(string)
}

variable "app_sg_id" {
  type = string
}

variable "instance_profile_name" {
  type = string
}

variable "target_group_arn" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "min_size" {
  type    = number
  default = 1
}

variable "desired_size" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 3
}

variable "artifacts_bucket" {
  description = "Bucket holding the Ansible playbooks"
  type        = string
}
