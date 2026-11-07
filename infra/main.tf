# -----------------------------------------------------------------------------
# Module: Networking (VPC, Subnets, Routing, NAT Gateway)
# -----------------------------------------------------------------------------

module "vpc" {
  source           = "../modules/vpc"
  project_name     = var.project_name
  environment      = var.environment
  vpc_cidr         = var.vpc_cidr
  nat_gateway_mode = var.nat_gateway_mode
}

# -----------------------------------------------------------------------------
# Module: Security Groups (Standalone Least-Privilege Ingress/Egress Rules)
# -----------------------------------------------------------------------------

module "security_groups" {
  source                  = "../modules/security-groups"
  project_name            = var.project_name
  environment             = var.environment
  vpc_id                  = module.vpc.vpc_id
  container_port          = var.container_port
  alb_ingress_cidr_blocks = var.alb_ingress_cidr_blocks
}

# -----------------------------------------------------------------------------
# Module: Application Load Balancer
# -----------------------------------------------------------------------------

module "alb" {
  source                     = "../modules/alb"
  project_name               = var.project_name
  environment                = var.environment
  vpc_id                     = module.vpc.vpc_id
  public_subnet_ids          = module.vpc.public_subnet_ids
  alb_security_group_id      = module.security_groups.alb_security_group_id
  container_port             = var.container_port
  health_check_path          = var.health_check_path
  enable_deletion_protection = var.enable_deletion_protection_alb
}

# -----------------------------------------------------------------------------
# Module: Amazon RDS PostgreSQL (Private, Encrypted, Managed Secrets)
# -----------------------------------------------------------------------------

module "rds" {
  source                  = "../modules/rds"
  project_name            = var.project_name
  environment             = var.environment
  private_db_subnet_ids   = module.vpc.private_db_subnet_ids
  rds_security_group_id   = module.security_groups.rds_security_group_id
  engine_version          = var.db_engine_version
  instance_class          = var.db_instance_class
  allocated_storage       = var.db_allocated_storage
  db_name                 = var.db_name
  db_username             = var.db_username
  backup_retention_period = var.db_backup_retention_period
  multi_az                = var.db_multi_az
  deletion_protection     = var.db_deletion_protection
  skip_final_snapshot     = var.db_skip_final_snapshot
}

# -----------------------------------------------------------------------------
# Module: ECS Fargate Service & Container Orchestration
# -----------------------------------------------------------------------------

module "ecs" {
  source                 = "../modules/ecs"
  project_name           = var.project_name
  environment            = var.environment
  aws_region             = var.aws_region
  private_app_subnet_ids = module.vpc.private_app_subnet_ids
  ecs_security_group_id  = module.security_groups.ecs_security_group_id
  target_group_arn       = module.alb.target_group_arn
  container_port         = var.container_port
  image_repo_url         = var.image_repo_url
  image_tag              = var.image_tag
  cpu                    = var.ecs_cpu
  memory                 = var.ecs_memory
  desired_count          = var.ecs_desired_count
  cpu_architecture       = var.ecs_cpu_architecture
  log_retention_in_days  = var.log_retention_in_days
  db_host                = module.rds.address
  db_port                = module.rds.port
  db_name                = module.rds.db_name
  db_user                = module.rds.db_username
  db_secret_arn          = module.rds.master_user_secret_arn
}

# -----------------------------------------------------------------------------
# CloudWatch Alarm: ALB UnHealthyHostCount (Operational Tier B)
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "${var.project_name}-${var.environment}-unhealthy-hosts"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  alarm_description   = "Triggers when an ECS container target fails ALB health checks for 2 consecutive minutes"

  dimensions = {
    TargetGroup  = module.alb.target_group_arn_suffix
    LoadBalancer = module.alb.alb_arn_suffix
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-unhealthy-hosts-alarm"
  }
}
