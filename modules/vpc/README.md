# VPC Terraform Module

This module provisions a 3-tier AWS Virtual Private Cloud (VPC) spanning two Availability Zones.

## Architecture & Subnetting

The module dynamically provisions subnets using `cidrsubnet(var.vpc_cidr, 4, ...)` across two available Availability Zones retrieved from the AWS region:
- **Public Subnets (2):** Host internet-facing Application Load Balancers and NAT Gateway. Route `0.0.0.0/0` directs traffic to an AWS Internet Gateway (IGW).
- **Private Application Subnets (2):** Host ECS Fargate container tasks. Route `0.0.0.0/0` directs egress traffic to the single NAT Gateway (when enabled).
- **Private Database Subnets (2):** Host private RDS PostgreSQL instances. Route table contains **no default internet gateway or NAT route**, providing network-level air-gapping.

## Usage

```hcl
module "vpc" {
  source           = "../modules/vpc"
  project_name     = "tfinfra"
  environment      = "dev"
  vpc_cidr         = "10.0.0.0/16"
  nat_gateway_mode = "single"
}
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `project_name` | `string` | — | Project naming identifier |
| `environment` | `string` | — | Target environment (`dev` or `staging`) |
| `vpc_cidr` | `string` | `"10.0.0.0/16"` | Primary VPC CIDR block |
| `nat_gateway_mode` | `string` | `"single"` | `"single"` or `"none"` |

## Outputs

| Name | Description |
|---|---|
| `vpc_id` | ID of the created VPC |
| `vpc_cidr_block` | Primary CIDR block |
| `public_subnet_ids` | List of 2 public subnet IDs |
| `private_app_subnet_ids` | List of 2 private app subnet IDs |
| `private_db_subnet_ids` | List of 2 private DB subnet IDs |
| `nat_gateway_id` | ID of the provisioned NAT Gateway (or null) |
| `availability_zones` | List of the 2 AZs used |

