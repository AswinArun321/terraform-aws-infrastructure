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
  description = "ID of the VPC in which security groups will be created."
  type        = string
}

variable "container_port" {
  description = "The port exposed by the application container (e.g., 8000)."
  type        = number
  default     = 8000
}

variable "alb_ingress_cidr_blocks" {
  description = "CIDR blocks permitted to access the ALB on HTTP port 80."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

