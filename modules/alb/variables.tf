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

variable "vpc_id" {
  description = "VPC ID where the ALB and Target Group reside."
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs (at least 2 in different AZs) to attach to the ALB."
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID attached to the ALB."
  type        = string
}

variable "container_port" {
  description = "Application container port to which the ALB forwards traffic."
  type        = number
  default     = 8000
}

variable "health_check_path" {
  description = "HTTP path for ALB target group health checks."
  type        = string
  default     = "/health"
}

variable "enable_deletion_protection" {
  description = "Enable or disable deletion protection on the ALB."
  type        = bool
  default     = false
}
