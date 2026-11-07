# ECS Fargate Terraform Module

This module provisions a containerized service running on AWS Fargate serverless infrastructure behind an Application Load Balancer.

## Key Capabilities

- **Serverless Fargate Execution:** No EC2 instances, AMI maintenance, or node patching required.
- **Air-Gapped Private Subnet Placement:** Tasks run with `assign_public_ip = false` in private application subnets, accessing AWS endpoints via NAT Gateway.
- **Explicit Runtime Platform:** Declares `operating_system_family = "LINUX"` and `cpu_architecture` (`X86_64` or `ARM64`) to prevent container architecture mismatch.
- **Secure Secret Ingestion:** The task execution role retrieves database credentials directly from AWS Secrets Manager using `${var.db_secret_arn}:password::` without exposing secrets in code, state, or task definitions.
- **Deployment Circuit Breaker:** Enables automated rollback on deployment failure, rolling back to the previous stable task definition if newly launched tasks fail ALB health checks.
- **Container Insights & Logging:** CloudWatch container logging with explicit log retention.

## Usage

```hcl
module "ecs" {
  source                  = "../modules/ecs"
  project_name            = "tfinfra"
  environment             = "dev"
  aws_region              = "us-east-1"
  private_app_subnet_ids  = module.vpc.private_app_subnet_ids
  ecs_security_group_id   = module.security_groups.ecs_security_group_id
  target_group_arn        = module.alb.target_group_arn
  container_port          = 8000
  image_repo_url          = "123456789012.dkr.ecr.us-east-1.amazonaws.com/tfinfra-app"
  image_tag               = "abc1234"
  cpu                     = "256"
  memory                  = "512"
  desired_count           = 1
  db_host                 = module.rds.address
  db_port                 = module.rds.port
  db_name                 = module.rds.db_name
  db_user                 = module.rds.db_username
  db_secret_arn           = module.rds.master_user_secret_arn
}
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `project_name` | `string` | — | Project naming identifier |
| `environment` | `string` | — | Target environment (`dev` or `staging`) |
| `aws_region` | `string` | `"us-east-1"` | AWS region |
| `private_app_subnet_ids` | `list(string)` | — | Private app subnets |
| `ecs_security_group_id` | `string` | — | Security group ID for ECS |
| `target_group_arn` | `string` | — | ALB Target Group ARN |
| `container_port` | `number` | `8000` | Port container listens on |
| `image_repo_url` | `string` | — | ECR repository URL |
| `image_tag` | `string` | `"latest"` | Image tag to deploy |
| `cpu` | `string` | `"256"` | Task CPU units |
| `memory` | `string` | `"512"` | Task memory in MiB |
| `desired_count` | `number` | `1` | Desired task count |
| `cpu_architecture` | `string` | `"X86_64"` | `"X86_64"` or `"ARM64"` |
| `db_host` | `string` | — | PostgreSQL hostname |
| `db_port` | `number` | `5432` | PostgreSQL port |
| `db_name` | `string` | `"appdb"` | Database name |
| `db_user` | `string` | `"dbadmin"` | Database username |
| `db_secret_arn` | `string` | — | Secrets Manager master secret ARN |

## Outputs

| Name | Description |
|---|---|
| `cluster_id` | ECS Cluster ID |
| `cluster_name` | ECS Cluster Name |
| `service_name` | ECS Service Name |
| `service_id` | ECS Service ID |
| `task_definition_arn` | Task Definition ARN |
| `cloudwatch_log_group_name` | CloudWatch Log Group Name |

