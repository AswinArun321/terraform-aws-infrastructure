variable "project_name" {
  description = "Project name identifier used for resource naming and tagging."
  type        = string
  default     = "tfinfra"
}

variable "environment" {
  description = "Target deployment environment (dev or staging)."
  type        = string

  validation {
    condition     = contains(["dev", "staging"], var.environment)
    error_message = "The environment variable must be either 'dev' or 'staging'."
  }
}

variable "aws_region" {
  description = "Target AWS region."
  type        = string
  default     = "us-east-1"
}

# -----------------------------------------------------------------------------
# Networking Variables
# -----------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the environment VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "nat_gateway_mode" {
  description = "NAT Gateway provisioning mode: 'single' or 'none'."
  type        = string
  default     = "single"

  validation {
    condition     = contains(["single", "none"], var.nat_gateway_mode)
    error_message = "nat_gateway_mode must be either 'single' or 'none'."
  }
}

variable "alb_ingress_cidr_blocks" {
  description = "Allowed CIDRs for inbound HTTP traffic to the ALB."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# -----------------------------------------------------------------------------
# Application & Compute Variables
# -----------------------------------------------------------------------------

variable "container_port" {
  description = "Port exposed by the demo container application."
  type        = number
  default     = 8000
}

variable "health_check_path" {
  description = "HTTP health check endpoint path."
  type        = string
  default     = "/health"
}

variable "image_repo_url" {
  description = "Amazon ECR repository URL containing the application container image."
  type        = string
}

variable "image_tag" {
  description = "Application image tag (git commit SHA recommended)."
  type        = string
  default     = "latest"
}

variable "ecs_cpu" {
  description = "ECS Task CPU allocation (e.g. 256 for 0.25 vCPU)."
  type        = string
  default     = "256"
}

variable "ecs_memory" {
  description = "ECS Task memory allocation in MiB (e.g. 512 for 0.5 GB)."
  type        = string
  default     = "512"
}

variable "ecs_desired_count" {
  description = "Number of desired task instances running in the ECS service."
  type        = number
  default     = 1
}

variable "ecs_cpu_architecture" {
  description = "Target architecture for Fargate tasks: 'X86_64' or 'ARM64'."
  type        = string
  default     = "X86_64"

  validation {
    condition     = contains(["X86_64", "ARM64"], var.ecs_cpu_architecture)
    error_message = "ecs_cpu_architecture must be 'X86_64' or 'ARM64'."
  }
}

variable "log_retention_in_days" {
  description = "Retention period for container CloudWatch logs."
  type        = number
  default     = 7
}

variable "enable_deletion_protection_alb" {
  description = "Enable or disable deletion protection on the ALB."
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Database Variables
# -----------------------------------------------------------------------------

variable "db_engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "16.3"
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GiB for RDS PostgreSQL."
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Initial database name created on RDS instance."
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username for RDS PostgreSQL."
  type        = string
  default     = "dbadmin"
}

variable "db_backup_retention_period" {
  description = "Automated backup retention days (1 for dev, 7 for staging)."
  type        = number
  default     = 1
}

variable "db_multi_az" {
  description = "Enable Multi-AZ deployment for RDS."
  type        = bool
  default     = false
}

variable "db_deletion_protection" {
  description = "Enable accidental deletion protection on RDS."
  type        = bool
  default     = false
}

variable "db_skip_final_snapshot" {
  description = "Skip final snapshot upon RDS destruction."
  type        = bool
  default     = true
}

