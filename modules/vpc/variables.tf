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

variable "availability_zone_names" {
  description = "Optional list of availability zone names to filter the available AZs. Defaults to wildcard matching all available zones in the region."
  type        = list(string)
  default     = ["*"]
}

variable "enable_flow_log" {
  description = "Whether to enable VPC Flow Logs. Defaults to false to prevent ongoing CloudWatch ingestion charges."
  type        = bool
  default     = false
}

variable "flow_log_destination_arn" {
  description = "The ARN of the CloudWatch Log Group or S3 bucket destination for VPC flow logs."
  type        = string
  default     = null
}

variable "flow_log_traffic_type" {
  description = "The type of traffic to capture in VPC Flow Logs (ALL, ACCEPT, REJECT)."
  type        = string
  default     = "ALL"
}

variable "flow_log_iam_role_arn" {
  description = "The ARN of the IAM role that allows AWS to publish flow logs to CloudWatch Logs."
  type        = string
  default     = null
}

