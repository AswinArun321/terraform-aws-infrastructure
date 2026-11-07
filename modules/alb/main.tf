# -----------------------------------------------------------------------------
# Application Load Balancer
# -----------------------------------------------------------------------------

resource "aws_lb" "this" {
  #checkov:skip=CKV_AWS_91: "ALB access logging is configurable via var.enable_access_logs and var.access_logs_bucket; disabled by default to avoid creating billable S3 storage in zero-cost environments"
  #checkov:skip=CKV2_AWS_28: "AWS WAF association is supported via var.web_acl_arn; disabled by default to prevent AWS WAF monthly rule fees ($5/rule/month) in zero-cost environments"
  #checkov:skip=CKV2_AWS_76: "AWS WAF AMR Log4j rule evaluation is managed on the external Web ACL supplied via var.web_acl_arn; Web ACL is not provisioned internally to avoid AWS WAF charges in zero-cost environments"
  name                       = "${var.project_name}-${var.environment}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [var.alb_security_group_id]
  subnets                    = var.public_subnet_ids
  enable_deletion_protection = var.enable_deletion_protection
  drop_invalid_header_fields = true

  dynamic "access_logs" {
    for_each = var.enable_access_logs && var.access_logs_bucket != null ? [1] : []
    content {
      bucket  = var.access_logs_bucket
      prefix  = var.access_logs_prefix
      enabled = true
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-alb"
  }
}

# -----------------------------------------------------------------------------
# Optional AWS WAFv2 Web ACL Association
# -----------------------------------------------------------------------------

resource "aws_wafv2_web_acl_association" "this" {
  count        = var.web_acl_arn != null ? 1 : 0
  resource_arn = aws_lb.this.arn
  web_acl_arn  = var.web_acl_arn
}

# -----------------------------------------------------------------------------
# Target Group (IP type for Fargate awsvpc mode)
# -----------------------------------------------------------------------------

resource "aws_lb_target_group" "this" {
  #checkov:skip=CKV_AWS_378: "Target group uses HTTP to communicate privately with Fargate container tasks inside the VPC; TLS termination is performed at the ALB"
  name        = "${var.project_name}-${var.environment}-tg"
  port        = var.container_port
  protocol    = var.target_group_protocol
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = var.health_check_path
    protocol            = var.health_check_protocol
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-tg"
  }
}

# -----------------------------------------------------------------------------
# Listeners: HTTP (:80) Redirect to HTTPS & HTTPS (:443) Forward
# -----------------------------------------------------------------------------

resource "aws_lb_listener" "http" {
  #checkov:skip=CKV_AWS_2: "HTTP listener redirects all traffic to HTTPS on port 443 with HTTP 301 status code"
  #checkov:skip=CKV_AWS_103: "TLS policy is enforced on the HTTPS listener (port 443)"
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  count             = var.certificate_arn != null ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}
