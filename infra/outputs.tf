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

output "app_url" {
  description = "Open this in a browser once the instances are healthy"
  value       = "http://${module.alb.dns_name}"
}

output "artifacts_bucket" {
  value = data.aws_s3_bucket.artifacts.id
}

output "ansible_document" {
  value = module.config_management.document_name
}

output "grafana_admin_password" {
  description = "Show with: terraform output -raw grafana_admin_password"
  value       = module.monitoring.grafana_admin_password
  sensitive   = true
}

output "grafana_port_forward_command" {
  description = "Run this, then open http://localhost:3000"
  value       = "aws ssm start-session --target ${module.monitoring.instance_id} --region ${var.region} --document-name AWS-StartPortForwardingSession --parameters portNumber=3000,localPortNumber=3000"
}

output "prometheus_port_forward_command" {
  description = "Run this, then open http://localhost:9090"
  value       = "aws ssm start-session --target ${module.monitoring.instance_id} --region ${var.region} --document-name AWS-StartPortForwardingSession --parameters portNumber=9090,localPortNumber=9090"
}
