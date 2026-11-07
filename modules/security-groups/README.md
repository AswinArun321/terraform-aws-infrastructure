# Security Groups Terraform Module

This module provisions least-privilege AWS security groups and rules for the multi-tier application.

## Design Principles

- **Standalone Rules:** Uses `aws_vpc_security_group_ingress_rule` and `aws_vpc_security_group_egress_rule` resources rather than inline security group blocks, preventing circular dependency cycles and state drift.
- **Strict SG References:** Inter-tier traffic (ALB -> ECS, ECS -> RDS) references source/destination Security Group IDs directly rather than network CIDRs.
- **Documented Rules:** Every rule contains a concise description explaining its necessity.

## Traffic Flow

| Tier | Inbound Allowed | Outbound Allowed |
|---|---|---|
| **ALB** | TCP 80 from allowed CIDRs (default `0.0.0.0/0`) | TCP `container_port` to ECS SG |
| **ECS Tasks** | TCP `container_port` strictly from ALB SG | TCP 5432 to RDS SG; TCP 443 to `0.0.0.0/0` (via NAT for AWS APIs) |
| **RDS** | TCP 5432 strictly from ECS SG | None |

## Usage

```hcl
module "security_groups" {
  source                  = "../modules/security-groups"
  project_name            = "tfinfra"
  environment             = "dev"
  vpc_id                  = module.vpc.vpc_id
  container_port          = 8000
  alb_ingress_cidr_blocks = ["0.0.0.0/0"]
}
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `project_name` | `string` | — | Project naming identifier |
| `environment` | `string` | — | Target environment (`dev` or `staging`) |
| `vpc_id` | `string` | — | Target VPC ID |
| `container_port` | `number` | `8000` | Port container listens on |
| `alb_ingress_cidr_blocks` | `list(string)` | `["0.0.0.0/0"]` | Allowed client ingress CIDRs |

## Outputs

| Name | Description |
|---|---|
| `alb_security_group_id` | Security Group ID for ALB |
| `ecs_security_group_id` | Security Group ID for ECS tasks |
| `rds_security_group_id` | Security Group ID for RDS instance |
