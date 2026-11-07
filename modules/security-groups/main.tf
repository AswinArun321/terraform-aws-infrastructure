# -----------------------------------------------------------------------------
# Security Groups: ALB, ECS Tasks, RDS
# -----------------------------------------------------------------------------

resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-${var.environment}-alb-sg-"
  description = "Security group for the public Application Load Balancer"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-sg"
  }
}

resource "aws_security_group" "ecs" {
  name_prefix = "${var.project_name}-${var.environment}-ecs-sg-"
  description = "Security group for ECS Fargate application tasks"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-sg"
  }
}

resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-${var.environment}-rds-sg-"
  description = "Security group for private RDS PostgreSQL database instance"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-rds-sg"
  }
}

# -----------------------------------------------------------------------------
# ALB Security Group Rules
# -----------------------------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "alb_http_in" {
  for_each          = toset(var.alb_ingress_cidr_blocks)
  security_group_id = aws_security_group.alb.id
  description       = "Allow inbound HTTP (port 80) traffic from allowed CIDRs"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "alb_to_ecs" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Allow outbound HTTP traffic from ALB to ECS tasks on container port"
  ip_protocol                  = "tcp"
  from_port                    = var.container_port
  to_port                      = var.container_port
  referenced_security_group_id = aws_security_group.ecs.id
}

# -----------------------------------------------------------------------------
# ECS Tasks Security Group Rules
# -----------------------------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "Allow inbound traffic on application port strictly from the ALB security group"
  ip_protocol                  = "tcp"
  from_port                    = var.container_port
  to_port                      = var.container_port
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_rds" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "Allow outbound PostgreSQL traffic from ECS tasks to RDS database on port 5432"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.rds.id
}

resource "aws_vpc_security_group_egress_rule" "ecs_https_out" {
  security_group_id = aws_security_group.ecs.id
  description       = "Allow outbound HTTPS traffic from ECS tasks for ECR pulls, CloudWatch logs, and Secrets Manager"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

# -----------------------------------------------------------------------------
# RDS Security Group Rules
# -----------------------------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "rds_from_ecs" {
  security_group_id            = aws_security_group.rds.id
  description                  = "Allow inbound PostgreSQL traffic on port 5432 strictly from ECS tasks security group"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.ecs.id
}

