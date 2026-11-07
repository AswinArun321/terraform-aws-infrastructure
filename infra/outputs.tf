output "environment" {
  description = "The deployed environment identifier (dev or staging)."
  value       = var.environment
}

output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer to access the demo application."
  value       = module.alb.alb_dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer."
  value       = module.alb.alb_arn
}

output "vpc_id" {
  description = "ID of the environment VPC."
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "Primary CIDR block of the environment VPC."
  value       = module.vpc.vpc_cidr_block
}

output "ecs_cluster_name" {
  description = "Name of the ECS Fargate cluster."
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "Name of the running ECS service."
  value       = module.ecs.service_name
}

output "rds_endpoint" {
  description = "PostgreSQL endpoint (host:port)."
  value       = module.rds.endpoint
}

output "rds_address" {
  description = "PostgreSQL host address."
  value       = module.rds.address
}

output "rds_secret_arn" {
  description = "ARN of the Secrets Manager secret managing the RDS master credentials."
  value       = module.rds.master_user_secret_arn
}

