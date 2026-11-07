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

variable "private_db_subnet_ids" {
  description = "List of private DB subnet IDs for the RDS DB subnet group."
  type        = list(string)
}

variable "rds_security_group_id" {
  description = "Security group ID attached to the RDS PostgreSQL instance."
  type        = string
}

variable "engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "16.3"
}

variable "instance_class" {
  description = "RDS instance class (e.g. db.t4g.micro for dev, db.t4g.small for staging)."
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in gibibytes (GiB)."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Upper limit in GiB for RDS autoscaling storage."
  type        = number
  default     = 50
}

variable "db_name" {
  description = "The name of the default database to create when the instance is provisioned."
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username for PostgreSQL database."
  type        = string
  default     = "dbadmin"
}

variable "backup_retention_period" {
  description = "The days to retain automated backups (e.g. 1 for dev, 7 for staging)."
  type        = number
  default     = 1
}

variable "multi_az" {
  description = "Whether to provision the RDS database in Multiple Availability Zones."
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Enable or disable accidental deletion protection."
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip taking a final DB snapshot before destroying the instance."
  type        = bool
  default     = true
}

variable "enabled_cloudwatch_logs_exports" {
  description = "Set of log types to enable for exporting to CloudWatch logs."
  type        = list(string)
  default     = ["postgresql", "upgrade"]
}

variable "iam_database_authentication_enabled" {
  description = "Whether to enable IAM database authentication."
  type        = bool
  default     = true
}

variable "performance_insights_enabled" {
  description = "Whether to enable Performance Insights for the database instance."
  type        = bool
  default     = true
}

variable "performance_insights_retention_period" {
  description = "Amount of time in days to retain Performance Insights data (7 days is free tier)."
  type        = number
  default     = 7
}

variable "performance_insights_kms_key_id" {
  description = "The ARN for the KMS key to encrypt Performance Insights data. If not specified, the default AWS-managed key will be used."
  type        = string
  default     = null
}

variable "parameter_group_family" {
  description = "The database parameter group family."
  type        = string
  default     = "postgres16"
}

variable "monitoring_interval" {
  description = "The interval, in seconds, between points when Enhanced Monitoring metrics are collected (0 to disable, 1, 5, 10, 15, 30, 60)."
  type        = number
  default     = 0
}

variable "monitoring_role_arn" {
  description = "The ARN for the IAM role that permits RDS to send enhanced monitoring metrics to CloudWatch Logs."
  type        = string
  default     = null
}


