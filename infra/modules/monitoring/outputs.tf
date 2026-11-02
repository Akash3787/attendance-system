output "instance_id" {
  value = aws_instance.monitoring.id
}

output "grafana_admin_password" {
  value     = random_password.grafana.result
  sensitive = true
}
