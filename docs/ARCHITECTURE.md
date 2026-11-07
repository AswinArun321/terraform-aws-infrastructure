# AWS Infrastructure Architecture

This document describes the architectural design, network topology, security model, and component interactions of the multi-tier AWS infrastructure provisioned with Terraform.

---

## 1. High-Level Architecture Diagram

```text
                                  Internet
                                     │
                                     │ HTTP (Port 80)
                                     ▼
                       ┌───────────────────────────┐
                       │ Application Load Balancer │
                       │    (Public Subnet AZ-a,   │
                       │     Public Subnet AZ-b)   │
                       └─────────────┬─────────────┘
                                     │
                                     │ HTTP (App Port 8000)
                                     ▼
                 ┌───────────────────────────────────────┐
                 │       AWS ECS Fargate Cluster         │
                 │ ┌───────────────────┐ ┌─────────────┐ │
                 │ │ Task (AZ-a)       │ │ Task (AZ-b) │ │
                 │ │ Private Subnet    │ │ Private Sub │ │
                 │ └─────────┬─────────┘ └──────┬──────┘ │
                 └───────────┼──────────────────┼────────┘
                             │                  │
         Outbound HTTPS 443  │                  │  PostgreSQL TCP 5432
         (ECR, CW, Secrets)  │                  │  (SSL Required)
                 ▼           │                  ▼
         ┌───────────────┐   │         ┌───────────────────┐
         │  NAT Gateway  │   │         │  RDS PostgreSQL   │
         │(Public AZ-a)  │◄──┘         │(Private DB Subnet)│
         └───────┬───────┘             └───────────────────┘
                 │
                 ▼
         ┌───────────────┐
         │ Internet GW   │
         └───────────────┘
```

---

## 2. Network Topology & Subnetting

The VPC uses a `/16` CIDR block (e.g., `10.0.0.0/16` for `dev`, `10.1.0.0/16` for `staging`). It spans **two Availability Zones (AZs)** and divides the address space cleanly into three distinct tiers using the Terraform `cidrsubnet()` function (`newbits = 4`, yielding `/20` subnets):

```text
VPC CIDR (10.0.0.0/16)
 ├── 10.0.0.0/20   ── Public Subnet AZ-a     (ALB, NAT Gateway)
 ├── 10.0.16.0/20  ── Public Subnet AZ-b     (ALB)
 ├── 10.0.32.0/20  ── Private App Subnet AZ-a (ECS Fargate Tasks)
 ├── 10.0.48.0/20  ── Private App Subnet AZ-b (ECS Fargate Tasks)
 ├── 10.0.64.0/20  ── Private DB Subnet AZ-a  (RDS PostgreSQL)
 └── 10.0.80.0/20  ── Private DB Subnet AZ-b  (RDS PostgreSQL)
```

### Subnet Routing Rules

1. **Public Subnets:**
   - Associated with the Public Route Table.
   - Default route `0.0.0.0/0` points directly to the AWS **Internet Gateway (IGW)**.
   - Hosts public endpoints: ALB and NAT Gateway Elastic IP.
2. **Private Application Subnets:**
   - Associated with the Private App Route Table.
   - Default route `0.0.0.0/0` points to the **NAT Gateway** in Public Subnet AZ-a (controlled by `var.nat_gateway_mode`).
   - No public IPv4 addresses assigned to ECS tasks (`assign_public_ip = false`).
3. **Private Database Subnets:**
   - Associated with the Private DB Route Table.
   - **Zero internet routes (`0.0.0.0/0` does not exist)**. Completely air-gapped from direct internet access.

---

## 3. Defense-in-Depth & Security Group Model

Security groups are configured with standalone `aws_vpc_security_group_ingress_rule` and `aws_vpc_security_group_egress_rule` resources to prevent cyclic dependencies and enforce least-privilege traffic flow.

```mermaid
graph TD
    Client["Public Client (Internet)"]
    ALB_SG["ALB Security Group"]
    ECS_SG["ECS Tasks Security Group"]
    RDS_SG["RDS Security Group"]
    NAT["AWS NAT Gateway"]
    AWSServices["AWS Services (ECR, CloudWatch, Secrets Mgr)"]

    Client -->|TCP 80| ALB_SG
    ALB_SG -->|TCP 8000 (App Port)| ECS_SG
    ECS_SG -->|TCP 5432 (Postgres)| RDS_SG
    ECS_SG -->|TCP 443 (HTTPS via NAT)| NAT
    NAT --> AWSServices
```

| Security Group | Direction | Protocol & Port | Source / Destination | Purpose |
|---|---|---|---|---|
| **ALB SG** | Ingress | TCP 80 | `0.0.0.0/0` (configurable) | Accept client HTTP traffic |
| **ALB SG** | Egress | TCP 8000 | `ECS Task SG` ID | Forward requests to healthy ECS task containers |
| **ECS Task SG** | Ingress | TCP 8000 | `ALB SG` ID | Accept reverse-proxied traffic from ALB only |
| **ECS Task SG** | Egress | TCP 5432 | `RDS SG` ID | Connect to PostgreSQL database |
| **ECS Task SG** | Egress | TCP 443 | `0.0.0.0/0` (via NAT) | Pull images from ECR, stream logs, fetch secrets |
| **RDS SG** | Ingress | TCP 5432 | `ECS Task SG` ID | Allow query access strictly from application containers |
| **RDS SG** | Egress | — | — | No outbound traffic allowed or needed |

---

## 4. Compute & Container Orchestration (ECS Fargate)

- **Execution Engine:** AWS Fargate serverless compute (no EC2 instances to patch or manage).
- **Runtime Platform:** Explicit `LINUX` OS with `X86_64` (or `ARM64`) architecture.
- **Task Networking:** `awsvpc` mode assigns each task an ENI within the private application subnets.
- **High Availability:** Tasks are distributed across two AZs with service `desired_count` configured per environment.
- **Rolling Deployments & Resilience:**
  - Deployment circuit breaker with automatic rollback enabled (`enable = true`, `rollback = true`).
  - Health check grace period prevents premature task restarts during container cold start.
  - ALB target group continuously polls `GET /health` with configurable thresholds.

---

## 5. Database Architecture & Secrets Management

- **Engine:** PostgreSQL on Amazon RDS.
- **Storage:** General Purpose SSD (`gp3`) with storage encryption enabled via AWS KMS.
- **TLS Enforcement & Query Auditing:** Parameter group enforces TLS via `rds.force_ssl = "1"` and logs all SQL queries with `log_statement = "all"` and `log_min_duration_statement = "1000"` (1 second threshold).
- **Diagnostics & Telemetry:** CloudWatch log exports enabled for `postgresql` and `upgrade` logs; Performance Insights enabled with 7-day free tier retention; IAM database authentication enabled (`iam_database_authentication_enabled = true`).
- **RDS-Managed Password Rotation & Storage:**
  - Master credentials are generated and managed directly by AWS via `manage_master_user_password = true`.
  - Passwords are **never stored in Terraform state**, `.tfvars` files, source control, or outputs.
  - The secret ARN (`aws_db_instance.this.master_user_secret[0].secret_arn`) is passed to the ECS module.
  - The ECS Task Execution IAM Role is granted scoped `secretsmanager:GetSecretValue` permission strictly on this secret ARN.
  - ECS securely injects the password into the container environment variable `DB_PASSWORD` at startup via the task definition `secrets` block.

---

## 6. Observability & Monitoring

- **Container Logs:** Forwarded to Amazon CloudWatch Logs using the `awslogs` log driver with 365-day compliance retention.
- **Encryption at Rest:** CloudWatch Log Group uses AWS-managed encryption by default, with optional customer-managed KMS key support via `var.cloudwatch_kms_key_arn`.
- **VPC Flow Logs:** Optional VPC network interface traffic auditing supported via `enable_vpc_flow_logs` and `flow_log_destination_arn`.
- **Health Checks:**
  - ALB Target Group monitors `GET /health` with HTTP/HTTPS configurable health checks.
  - Application exposes `GET /db-check` to confirm end-to-end database connectivity and SSL enforcement.
- **Alarms:** CloudWatch alarm on ALB `UnHealthyHostCount` alerts on any sustained container degradation.


