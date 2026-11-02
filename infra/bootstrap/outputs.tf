output "state_bucket_name" {
  description = "Bucket that will hold the main Terraform state"
  value       = aws_s3_bucket.state.id
}

output "region" {
  value = var.region
}
