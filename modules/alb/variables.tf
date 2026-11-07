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
  default     = true
}

variable "certificate_arn" {
  description = "Optional ACM certificate ARN for enabling HTTPS on the ALB. When omitted, HTTPS listener is disabled."
  type        = string
  default     = null
}

variable "ssl_policy" {
  description = "Security policy for the ALB HTTPS listener enforcing TLS 1.2+."
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "enable_access_logs" {
  description = "Enable or disable S3 access logging for the Application Load Balancer."
  type        = bool
  default     = false
}

variable "access_logs_bucket" {
  description = "S3 bucket name to store ALB access logs."
  type        = string
  default     = null
}

variable "access_logs_prefix" {
  description = "S3 prefix/folder for ALB access logs."
  type        = string
  default     = "alb-logs"
}

variable "web_acl_arn" {
  description = "Optional ARN of an AWS WAFv2 Web ACL to associate with the Application Load Balancer."
  type        = string
  default     = null
}

variable "target_group_protocol" {
  description = "Protocol to use for routing traffic to targets (HTTP or HTTPS)."
  type        = string
  default     = "HTTP"
}

variable "health_check_protocol" {
  description = "Protocol to use for health check requests (HTTP or HTTPS)."
  type        = string
  default     = "HTTP"
}


