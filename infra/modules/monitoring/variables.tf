variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "subnet_id" {
  description = "Public subnet for the monitoring server"
  type        = string
}

variable "monitoring_sg_id" {
  type = string
}

variable "artifacts_bucket" {
  description = "Bucket holding the Ansible playbooks"
  type        = string
}

variable "artifacts_bucket_arn" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}
