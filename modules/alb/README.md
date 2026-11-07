# Application Load Balancer (ALB) Terraform Module

This module provisions an internet-facing AWS Application Load Balancer and an IP-type Target Group configured for ECS Fargate tasks.

## Features

- **Public Internet Ingress:** Spans public subnets across 2 Availability Zones.
- **Header Sanitization:** Enables `drop_invalid_header_fields` for HTTP request hardening.
- **IP Target Group:** Uses `target_type = "ip"` required by ECS Fargate with `awsvpc` network mode.
- **Configurable Health Checks:** Polling `/health` with automatic unhealthy host detection.
- **32-Character Naming Compliance:** Strict naming convention ensures names stay well under AWS's 32-character limit.

## Usage

```hcl
module "alb" {
  source                     = "../modules/alb"
  project_name               = "tfinfra"
  environment                = "dev"
  vpc_id                     = module.vpc.vpc_id
  public_subnet_ids          = module.vpc.public_subnet_ids
  alb_security_group_id      = module.security_groups.alb_security_group_id
  container_port             = 8000
  health_check_path          = "/health"
  enable_deletion_protection = false
}
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `project_name` | `string` | — | Project naming identifier |
| `environment` | `string` | — | Target environment (`dev` or `staging`) |
| `vpc_id` | `string` | — | VPC ID |
| `public_subnet_ids` | `list(string)` | — | List of public subnet IDs |
| `alb_security_group_id` | `string` | — | Security group ID for the ALB |
| `container_port` | `number` | `8000` | Port container listens on |
| `health_check_path` | `string` | `"/health"` | Path for target health checks |
| `enable_deletion_protection` | `bool` | `false` | Prevent accidental ALB deletion |

## Outputs

| Name | Description |
|---|---|
| `alb_dns_name` | Public DNS name of the ALB |
| `alb_arn` | ARN of the ALB |
| `target_group_arn` | ARN of the Target Group (passed to ECS) |
| `listener_arn` | ARN of the port 80 listener |
