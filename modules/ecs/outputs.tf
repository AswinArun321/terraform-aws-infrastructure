output "cluster_id" {
  description = "The ID of the ECS Cluster."
  value       = aws_ecs_cluster.this.id
}

output "cluster_name" {
  description = "The name of the ECS Cluster."
  value       = aws_ecs_cluster.this.name
}

output "service_name" {
  description = "The name of the ECS Service."
  value       = aws_ecs_service.this.name
}

output "service_id" {
  description = "The ID of the ECS Service."
  value       = aws_ecs_service.this.id
}

output "task_definition_arn" {
  description = "The ARN of the ECS Task Definition."
  value       = aws_ecs_task_definition.this.arn
}

output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch Log Group for container logs."
  value       = aws_cloudwatch_log_group.this.name
}

