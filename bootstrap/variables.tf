variable "aws_region" {
  description = "AWS region for provisioning bootstrap resources."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name prefix for naming resources and tagging."
  type        = string
  default     = "tfinfra"
}

variable "state_bucket_name" {
  description = "Optional explicit name for the Terraform state S3 bucket. If omitted, defaults to <project_name>-state-<account_id>."
  type        = string
  default     = null
}

variable "ecr_repository_name" {
  description = "Name of the Amazon ECR repository for the application container image."
  type        = string
  default     = "tfinfra-app"
}

