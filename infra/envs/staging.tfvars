# Staging Environment Configuration (Non-secret, committed)

project_name = "tfinfra"
environment  = "staging"
aws_region   = "us-east-1"

# Networking (Distinct VPC CIDR for complete network isolation)
vpc_cidr                = "10.1.0.0/16"
nat_gateway_mode        = "single"
alb_ingress_cidr_blocks = ["0.0.0.0/0"]

# Application & Compute (Fargate scaled for staging load)
container_port                 = 8000
health_check_path              = "/health"
image_repo_url                 = "123456789012.dkr.ecr.us-east-1.amazonaws.com/tfinfra-app"
image_tag                      = "latest"
ecs_cpu                        = "512"
ecs_memory                     = "1024"
ecs_desired_count              = 2
ecs_cpu_architecture           = "X86_64"
log_retention_in_days          = 30
enable_deletion_protection_alb = true

# Database (RDS PostgreSQL with protection & 7-day retention)
db_engine_version          = "16.3"
db_instance_class          = "db.t4g.small"
db_allocated_storage       = 30
db_name                    = "appdb"
db_username                = "dbadmin"
db_backup_retention_period = 7
db_multi_az                = false
db_deletion_protection     = true
db_skip_final_snapshot     = false

