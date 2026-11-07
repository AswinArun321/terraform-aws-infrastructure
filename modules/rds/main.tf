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
# RDS PostgreSQL Instance
# -----------------------------------------------------------------------------

resource "aws_db_instance" "this" {
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
  vpc_security_group_ids = [var.rds_security_group_id]

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
