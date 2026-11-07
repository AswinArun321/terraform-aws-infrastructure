# Development Environment Configuration (Non-secret, committed)

project_name = "tfinfra"
environment  = "dev"
aws_region   = "us-east-1"

# Networking
vpc_cidr                = "10.0.0.0/16"
nat_gateway_mode        = "single"
alb_ingress_cidr_blocks = ["103.214.233.242/32"]

# Application & Compute (Fargate)
container_port                 = 8000
health_check_path              = "/health"
image_repo_url                 = "123456789012.dkr.ecr.us-east-1.amazonaws.com/tfinfra-app"
image_tag                      = "latest"
ecs_cpu                        = "256"
ecs_memory                     = "512"
ecs_desired_count              = 1
ecs_cpu_architecture           = "X86_64"
log_retention_in_days          = 365
enable_deletion_protection_alb = true

# Database (RDS PostgreSQL)
db_engine_version          = "16.3"
db_instance_class          = "db.t4g.micro"
db_allocated_storage       = 20
db_name                    = "appdb"
db_username                = "dbadmin"
db_backup_retention_period = 1
db_multi_az                = false
db_deletion_protection     = true
db_skip_final_snapshot     = true


