variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "artifacts_bucket" {
  description = "Bucket holding the Ansible playbooks"
  type        = string
}

variable "ecr_repository_url" {
  type = string
}

variable "db_secret_arn" {
  type = string
}

variable "app_secret_arn" {
  type = string
}

variable "image_tag" {
  type    = string
  default = "latest"
}
