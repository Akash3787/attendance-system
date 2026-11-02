variable "region" {
  description = "AWS region used for the whole project"
  type        = string
  default     = "us-east-1"
}

variable "alert_email" {
  description = "Email that receives budget alerts"
  type        = string
}

variable "monthly_budget_usd" {
  description = "Monthly budget in USD that triggers the alerts"
  type        = number
  default     = 10
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository for the app image"
  type        = string
  default     = "attendance-app"
}

variable "github_repo" {
  description = "GitHub repository allowed to deploy, as owner/name"
  type        = string
  default     = "Akash3787/attendance-system"
}
