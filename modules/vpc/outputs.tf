output "vpc_id" {
  description = "The ID of the provisioned VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "The primary CIDR block of the provisioned VPC."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "List of IDs of the public subnets across 2 AZs."
  value       = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  description = "List of IDs of the private application subnets across 2 AZs."
  value       = aws_subnet.private_app[*].id
}

output "private_db_subnet_ids" {
  description = "List of IDs of the private database subnets across 2 AZs."
  value       = aws_subnet.private_db[*].id
}

output "nat_gateway_id" {
  description = "The ID of the NAT Gateway, if enabled."
  value       = length(aws_nat_gateway.this) > 0 ? aws_nat_gateway.this[0].id : null
}

output "availability_zones" {
  description = "The availability zones utilized for subnet provisioning."
  value       = local.azs
}
