data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "zone-name"
    values = var.availability_zone_names
  }
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

# -----------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------

resource "aws_vpc" "this" {
  #checkov:skip=CKV2_AWS_11: "VPC flow logging is supported via aws_flow_log and var.enable_flow_log; disabled by default to maintain zero-cost operation without incurring CloudWatch log ingestion charges"
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

# -----------------------------------------------------------------------------
# Subnets: 2 Public, 2 Private App, 2 Private DB
# -----------------------------------------------------------------------------

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-${var.environment}-public-${local.azs[count.index]}"
    Tier = "public"
  }
}

resource "aws_subnet" "private_app" {
  count                   = 2
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index + 2)
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-${var.environment}-private-app-${local.azs[count.index]}"
    Tier = "private-app"
  }
}

resource "aws_subnet" "private_db" {
  count                   = 2
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index + 4)
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-${var.environment}-private-db-${local.azs[count.index]}"
    Tier = "private-db"
  }
}

# -----------------------------------------------------------------------------
# Internet Gateway & Public Routing
# -----------------------------------------------------------------------------

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# -----------------------------------------------------------------------------
# NAT Gateway (Single for dev/staging egress) & Private App Routing
# -----------------------------------------------------------------------------

resource "aws_eip" "nat" {
  count  = var.nat_gateway_mode == "single" ? 1 : 0
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-eip"
  }
}

resource "aws_nat_gateway" "this" {
  count         = var.nat_gateway_mode == "single" ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-gw"
  }

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "private_app" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-${var.environment}-private-app-rt"
  }
}

resource "aws_route" "private_app_nat" {
  count                  = var.nat_gateway_mode == "single" ? 1 : 0
  route_table_id         = aws_route_table.private_app.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[0].id
}

resource "aws_route_table_association" "private_app" {
  count          = 2
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private_app.id
}

# -----------------------------------------------------------------------------
# Private DB Routing (Air-gapped: strictly no internet route)
# -----------------------------------------------------------------------------

resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-${var.environment}-private-db-rt"
  }
}

resource "aws_route_table_association" "private_db" {
  count          = 2
  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private_db.id
}

# -----------------------------------------------------------------------------
# Default Security Group - Deny All Traffic
# -----------------------------------------------------------------------------

resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id

  ingress = []
  egress  = []

  tags = {
    Name = "${var.project_name}-${var.environment}-default-sg"
  }
}

# -----------------------------------------------------------------------------
# VPC Flow Logs (Configurable via var.enable_flow_log)
# -----------------------------------------------------------------------------

resource "aws_flow_log" "this" {
  count                = var.enable_flow_log ? 1 : 0
  vpc_id               = aws_vpc.this.id
  traffic_type         = var.flow_log_traffic_type
  log_destination_type = var.flow_log_iam_role_arn != null ? "cloud-watch-logs" : "s3"
  log_destination      = var.flow_log_destination_arn
  iam_role_arn         = var.flow_log_iam_role_arn

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc-flow-log"
  }
}
