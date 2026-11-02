variable "name" {
  type = string
}

variable "admin_email" {
  description = "Login email of the first teacher account"
  type        = string
}

variable "admin_name" {
  type    = string
  default = "Admin Teacher"
}
