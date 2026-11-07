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

variable "vpc_cidr" {
  description = "The CIDR block for the VPC (e.g., 10.0.0.0/16)."
  type        = string
  default     = "10.0.0.0/16"
}

variable "nat_gateway_mode" {
  description = "NAT Gateway provisioning mode: 'single' provisions one NAT gateway in the first public subnet; 'none' provisions zero."
  type        = string
  default     = "single"

  validation {
    condition     = contains(["single", "none"], var.nat_gateway_mode)
    error_message = "nat_gateway_mode must be either 'single' or 'none'."
  }
}

