variable "name" {
  description = "Name prefix"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets for the database"
  type        = list(string)
}

variable "db_sg_id" {
  description = "Security group attached to the database"
  type        = string
}

variable "instance_class" {
  description = "RDS instance size"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_name" {
  description = "Name of the initial database"
  type        = string
  default     = "attendance"
}

variable "db_username" {
  description = "Master username"
  type        = string
  default     = "attendance"
}

variable "allocated_storage" {
  description = "Storage in GB"
  type        = number
  default     = 20
}

variable "backup_retention_days" {
  description = "Days of automated backups (free-tier accounts allow at most 1)"
  type        = number
  default     = 1
}
