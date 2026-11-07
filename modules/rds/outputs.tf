output "endpoint" {
  description = "The connection endpoint in address:port format."
  value       = aws_db_instance.this.endpoint
}

output "address" {
  description = "The hostname address of the RDS PostgreSQL instance."
  value       = aws_db_instance.this.address
}

output "port" {
  description = "The port on which the RDS PostgreSQL database accepts connections."
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "The database name."
  value       = aws_db_instance.this.db_name
}

output "db_username" {
  description = "The master username for the database."
  value       = aws_db_instance.this.username
}

output "master_user_secret_arn" {
  description = "The ARN of the AWS Secrets Manager secret holding the RDS-managed master password."
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}

