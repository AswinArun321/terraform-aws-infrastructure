output "state_bucket_name" {
  description = "Name of the provisioned Terraform remote state S3 bucket."
  value       = aws_s3_bucket.state.id
}

output "state_bucket_arn" {
  description = "ARN of the provisioned Terraform remote state S3 bucket."
  value       = aws_s3_bucket.state.arn
}

output "ecr_repository_url" {
  description = "Registry URL of the Amazon ECR repository for application container images."
  value       = aws_ecr_repository.app.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the Amazon ECR repository."
  value       = aws_ecr_repository.app.arn
}

output "ecr_repository_name" {
  description = "Name of the Amazon ECR repository."
  value       = aws_ecr_repository.app.name
}

