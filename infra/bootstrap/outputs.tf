output "state_bucket_name" {
  description = "Bucket that will hold the main Terraform state"
  value       = aws_s3_bucket.state.id
}

output "region" {
  value = var.region
}

output "ecr_repository_url" {
  description = "Where to push the Docker image"
  value       = aws_ecr_repository.app.repository_url
}

output "artifacts_bucket_name" {
  description = "Upload the Ansible playbooks here"
  value       = aws_s3_bucket.artifacts.id
}

output "github_actions_role_arn" {
  description = "Role the GitHub Actions workflow assumes"
  value       = aws_iam_role.github_actions.arn
}
