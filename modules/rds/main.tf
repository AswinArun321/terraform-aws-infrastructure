# -----------------------------------------------------------------------------
# RDS Subnet Group
# -----------------------------------------------------------------------------

resource "aws_db_subnet_group" "this" {
  name_prefix = "${var.project_name}-${var.environment}-db-subnets-"
  description = "Private DB subnets for ${var.project_name} ${var.environment}"
  subnet_ids  = var.private_db_subnet_ids

  tags = {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  }
}

# -----------------------------------------------------------------------------
# RDS Parameter Group (PostgreSQL Query Logging)
# -----------------------------------------------------------------------------

resource "aws_db_parameter_group" "this" {
  name_prefix = "${var.project_name}-${var.environment}-pg-params-"
  family      = var.parameter_group_family
  description = "PostgreSQL parameter group enabling query logging for ${var.project_name} ${var.environment}"

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-pg-parameter-group"
  }
}

# -----------------------------------------------------------------------------
# RDS PostgreSQL Instance
# -----------------------------------------------------------------------------

resource "aws_db_instance" "this" {
  #checkov:skip=CKV_AWS_118: "Enhanced monitoring is configurable via var.monitoring_interval and var.monitoring_role_arn; disabled by default (0) to avoid extra CloudWatch ingestion costs in zero-cost environments"
  #checkov:skip=CKV_AWS_157: "Multi-AZ is configurable via var.multi_az; disabled by default in development to avoid doubling RDS instance hourly costs"
  #checkov:skip=CKV_AWS_354: "Performance Insights encryption uses the AWS-managed KMS key in the free tier; customer-managed KMS key ARN is configurable via var.performance_insights_kms_key_id"
  identifier = "${var.project_name}-${var.environment}-pg"

  engine                = "postgres"
  engine_version        = var.engine_version
  instance_class        = var.instance_class
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username

  # RDS-managed master password in AWS Secrets Manager (no passwords in state/code)
  manage_master_user_password = true

  publicly_accessible    = false
  db_subnet_group_name   = aws_db_subnet_group.this.name
  parameter_group_name   = aws_db_parameter_group.this.name
  vpc_security_group_ids = [var.rds_security_group_id]

  # Logging, IAM Authentication, and Performance Insights
  enabled_cloudwatch_logs_exports       = var.enabled_cloudwatch_logs_exports
  iam_database_authentication_enabled   = var.iam_database_authentication_enabled
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_retention_period
  performance_insights_kms_key_id       = var.performance_insights_kms_key_id

  # Enhanced Monitoring
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_role_arn

  multi_az                  = var.multi_az
  backup_retention_period   = var.backup_retention_period
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.project_name}-${var.environment}-pg-final-${formatdate("YYYYMMDDhhmmss", timestamp())}"

  auto_minor_version_upgrade = true
  copy_tags_to_snapshot      = true

  lifecycle {
    ignore_changes = [
      final_snapshot_identifier
    ]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-pg"
  }
}
