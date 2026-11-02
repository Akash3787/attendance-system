variable "name" {
  type = string
}

variable "ecr_repository_arn" {
  description = "Repository the servers may pull images from"
  type        = string
}

variable "secret_arns" {
  description = "Secrets the servers may read"
  type        = list(string)
}
