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
