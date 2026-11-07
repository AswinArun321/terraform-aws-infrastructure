variable "project_name" {
  description = "Project name identifier used for resource naming and tagging."
  type        = string
}

variable "environment" {
  description = "Target deployment environment (e.g., dev, staging)."
  type        = string

  validation {
    condition     = contains(["dev", "staging"], var.environment)
    error_message = "The environment variable must be either 'dev' or 'staging'."
  }
}

variable "aws_region" {
  description = "AWS region for CloudWatch logs configuration."
  type        = string
  default     = "us-east-1"
}

variable "private_app_subnet_ids" {
  description = "List of private application subnet IDs where Fargate tasks will run."
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group ID attached to the ECS Fargate tasks."
  type        = string
}

variable "target_group_arn" {
  description = "Target group ARN of the Application Load Balancer to register tasks with."
  type        = string
}

variable "container_port" {
  description = "The port on which the container application listens."
  type        = number
  default     = 8000
}

variable "image_repo_url" {
  description = "ECR repository URL holding the container image."
  type        = string
}

variable "image_tag" {
  description = "Image tag to deploy (e.g., git commit short SHA)."
  type        = string
  default     = "latest"
}

variable "cpu" {
  description = "Fargate task CPU units (e.g., 256 for 0.25 vCPU, 512 for 0.5 vCPU)."
  type        = string
  default     = "256"
}

variable "memory" {
  description = "Fargate task memory in MiB (e.g., 512 for 0.5 GB, 1024 for 1 GB)."
  type        = string
  default     = "512"
}

variable "desired_count" {
  description = "Number of task instances to maintain in the ECS service."
  type        = number
  default     = 1
}

variable "cpu_architecture" {
  description = "CPU architecture for the Fargate runtime platform ('X86_64' or 'ARM64')."
  type        = string
  default     = "X86_64"

  validation {
    condition     = contains(["X86_64", "ARM64"], var.cpu_architecture)
    error_message = "cpu_architecture must be 'X86_64' or 'ARM64'."
  }
}

variable "log_retention_in_days" {
  description = "Number of days to retain container logs in CloudWatch Logs."
  type        = number
  default     = 7
}

variable "health_check_grace_period_seconds" {
  description = "Seconds to ignore failing health checks after a new task starts."
  type        = number
  default     = 60
}

variable "db_host" {
  description = "PostgreSQL database hostname."
  type        = string
}

variable "db_port" {
  description = "PostgreSQL database port."
  type        = number
  default     = 5432
}

variable "db_name" {
  description = "PostgreSQL database name."
  type        = string
  default     = "appdb"
}

variable "db_user" {
  description = "PostgreSQL database username."
  type        = string
  default     = "dbadmin"
}

variable "db_secret_arn" {
  description = "ARN of the AWS Secrets Manager secret holding the RDS master password."
  type        = string
}
