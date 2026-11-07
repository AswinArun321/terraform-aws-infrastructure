output "alb_dns_name" {
  description = "The public DNS name of the Application Load Balancer."
  value       = aws_lb.this.dns_name
}

output "alb_arn" {
  description = "The ARN of the Application Load Balancer."
  value       = aws_lb.this.arn
}

output "alb_arn_suffix" {
  description = "The ARN suffix of the ALB (useful for CloudWatch metric dimensions)."
  value       = aws_lb.this.arn_suffix
}

output "target_group_arn" {
  description = "The ARN of the ALB Target Group."
  value       = aws_lb_target_group.this.arn
}

output "target_group_arn_suffix" {
  description = "The ARN suffix of the Target Group (useful for CloudWatch metric dimensions)."
  value       = aws_lb_target_group.this.arn_suffix
}

output "listener_arn" {
  description = "The ARN of the HTTP listener."
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "The ARN of the HTTPS listener (if certificate_arn was provided)."
  value       = try(aws_lb_listener.https[0].arn, null)
}


