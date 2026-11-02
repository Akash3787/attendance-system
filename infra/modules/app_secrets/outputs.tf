output "secret_arn" {
  value = aws_secretsmanager_secret.app.arn
}

output "admin_password" {
  value     = random_password.admin.result
  sensitive = true
}
