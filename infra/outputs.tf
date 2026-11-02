output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "security_group_ids" {
  value = {
    alb = module.network.alb_sg_id
    app = module.network.app_sg_id
    db  = module.network.db_sg_id
  }
}

output "db_endpoint" {
  value = module.database.endpoint
}

output "db_secret_arn" {
  value = module.database.secret_arn
}

output "ecr_repository_url" {
  value = data.aws_ecr_repository.app.repository_url
}

output "admin_email" {
  value = var.admin_email
}

output "admin_password" {
  description = "Show with: terraform output -raw admin_password"
  value       = module.app_secrets.admin_password
  sensitive   = true
}
