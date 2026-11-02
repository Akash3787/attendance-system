output "instance_profile_name" {
  value = aws_iam_instance_profile.app.name
}

output "role_name" {
  value = aws_iam_role.app.name
}
