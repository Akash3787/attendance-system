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
