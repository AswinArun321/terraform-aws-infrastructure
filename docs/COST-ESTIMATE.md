# AWS Infrastructure Cost Estimate

This document provides estimated monthly and hourly operating costs for the AWS infrastructure provisioned by this repository, covering both **development (`dev`)** and **staging (`staging`)** environments.

---

## 1. Cost Drivers Overview

The main cost drivers in this architecture are:
1. **AWS NAT Gateway**: Hourly charge + per-GB data processing.
2. **AWS Application Load Balancer (ALB)**: Hourly base charge + Load Balancer Capacity Units (LCU-hour).
3. **AWS RDS PostgreSQL Instance**: Hourly db instance pricing + allocated gp3 storage + backup storage.
4. **AWS Fargate (ECS Tasks)**: vCPU-hours and GB-memory-hours consumed by container tasks.
5. **AWS Public IPv4 Addresses**: Billed per in-use public IP (NAT Gateway, ALB).
6. **Auxiliary Services**: Amazon CloudWatch Logs retention and Amazon ECR storage.

---

## 2. Resource Specifications & Assumptions

- **Target Region:** `us-east-1` (N. Virginia)
- **Currency:** USD ($)
- **Billing Duration Basis:** 730 hours/month (for steady state) or on-demand hourly rates for short-lived test sessions.
- **Data Transfer:** Assumes modest baseline test traffic (< 10 GB/month).

### Sizing Comparison: Dev vs. Staging

| Dimension | Development (`dev`) | Staging (`staging`) |
|---|---|---|
| **VPC CIDR** | `10.0.0.0/16` | `10.1.0.0/16` |
| **NAT Gateways** | 1 (Single AZ) | 1 (Single AZ) / Optional Multi-AZ |
| **ALB** | 1 internet-facing | 1 internet-facing |
| **ECS Fargate Tasks** | 1 task (0.25 vCPU, 0.5 GB RAM) | 2 tasks (0.5 vCPU, 1 GB RAM) |
| **RDS Instance Type** | `db.t4g.micro` (2 vCPU, 1 GB RAM) | `db.t4g.small` (2 vCPU, 2 GB RAM) |
| **RDS Deployment** | Single-AZ | Single-AZ (Multi-AZ optional) |
| **RDS Storage** | 20 GB gp3 | 30 GB gp3 |
| **RDS Backup Retention** | 1 day | 7 days |
| **Deletion Protection** | Disabled (fast destroy) | Enabled (accidental drop protection) |
| **Final Snapshot** | Skipped | Created upon destroy |

---

## 3. Detailed Cost Breakdown (Monthly Steady State)

### Development Environment (`dev`)

| Resource | Configuration | Unit Rate | Est. Monthly Cost |
|---|---|---|---|
| **NAT Gateway** | 1 single NAT gateway | ~$0.045 / hr | $32.85 |
| **NAT Data Processing** | Est. 5 GB / month | $0.045 / GB | $0.23 |
| **Public IPv4 Addresses** | 1 for NAT + 2 for ALB ENIs = 3 IPs | $0.005 / IP / hr | $10.95 |
| **Application Load Balancer** | 1 ALB | ~$0.0225 / hr | $16.43 |
| **ALB LCU Usage** | ~0.5 LCU baseline | ~$0.008 / LCU-hr | $2.92 |
| **ECS Fargate (Tasks)** | 1 task × 0.25 vCPU ($0.04048/vCPU-hr) + 0.5 GB ($0.004445/GB-hr) | ~$0.0123 / hr | $9.01 |
| **RDS PostgreSQL** | `db.t4g.micro` (Single-AZ) | ~$0.016 / hr | $11.68 |
| **RDS gp3 Storage** | 20 GB gp3 storage | $0.115 / GB-month | $2.30 |
| **RDS Backup Storage** | 1 day retention (< allocated storage) | Free tier baseline | $0.00 |
| **ECR Storage** | 1 repository (~0.5 GB image storage) | $0.10 / GB-month | $0.05 |
| **CloudWatch Logs** | 7-day retention, < 1 GB ingested | $0.50 / GB ingested | $0.50 |
| **Total (Dev - Continuous)** | | | **~$86.92 / month** |

### Staging Environment (`staging`)

| Resource | Configuration | Unit Rate | Est. Monthly Cost |
|---|---|---|---|
| **NAT Gateway** | 1 single NAT gateway | ~$0.045 / hr | $32.85 |
| **NAT Data Processing** | Est. 10 GB / month | $0.045 / GB | $0.45 |
| **Public IPv4 Addresses** | 3 in-use IPs | $0.005 / IP / hr | $10.95 |
| **Application Load Balancer** | 1 ALB + 1 LCU | ~$0.0305 / hr | $22.27 |
| **ECS Fargate (Tasks)** | 2 tasks × 0.5 vCPU + 1.0 GB RAM | ~$0.0494 / hr | $36.06 |
| **RDS PostgreSQL** | `db.t4g.small` (Single-AZ) | ~$0.032 / hr | $23.36 |
| **RDS gp3 Storage** | 30 GB gp3 storage | $0.115 / GB-month | $3.45 |
| **RDS Backup Storage** | 7 days retention (~30 GB backup) | Beyond free allowance | ~$1.50 |
| **ECR & CloudWatch** | Enhanced logging & telemetry | Baseline | $1.50 |
| **Total (Staging - Continuous)** | | | **~$132.39 / month** |

---

## 4. Ephemeral Test Run Cost (Timed Demonstration)

Because educational and portfolio verification environments are deployed, tested, and destroyed on the same day, the actual testing cost is minuscule:

| Duration | Dev Environment Cost | Staging Environment Cost | Combined Isolation Test (2 hrs) |
|---|---|---|---|
| **1 Hour** | **~$0.12** | **~$0.18** | ~$0.30 |
| **3 Hours** | **~$0.36** | **~$0.54** | ~$0.90 |
| **Full Day (8 Hours)** | **~$0.95** | **~$1.45** | ~$2.40 |

> **Key Takeaway:** Running the automated test suite and timed apply/destroy runs costs **less than $1.00** when destroyed after verification.

---

## 5. Cost Optimization Strategies

1. **`nat_gateway_mode = "none"` During Early Network Validation:**
   - Setting `nat_gateway_mode = "none"` allows testing VPC, subnets, route tables, and security groups completely free of charge before ECS tasks need outbound internet connectivity.
2. **Ephemeral Deployment Cadence:**
   - Always run `terraform destroy -var-file=envs/dev.tfvars` at the end of the work session.
3. **AWS Budgets Alerting:**
   - Configure a budget of **$10.00/month** with email alerts at 50% ($5.00), 80% ($8.00), and 100% ($10.00) thresholds to avoid surprise billing.
4. **Log Retention Limits:**
   - CloudWatch log groups are explicitly configured with `retention_in_days = 7` (dev) to prevent unbounded log storage accumulation.
5. **Graviton (ARM64) Instances:**
   - `db.t4g` instances use AWS Graviton2 processors, providing up to 20% cost savings over comparable x86 `db.t3` instances.

