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
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip taking a final DB snapshot before destroying the instance."
  type        = bool
  default     = true
}

