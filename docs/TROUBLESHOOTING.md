# Infrastructure Troubleshooting Guide

This guide details common operational issues, error messages, and verified resolutions encountered when provisioning and operating the infrastructure.

---

## 1. Container Task Startup Failures (`CrashLoopBackOff` / Task Stopped)

### Symptoms
ECS service reports `desiredCount: 1, runningCount: 0` or service event log shows:
```text
(service tfinfra-dev-service) has stopped 1 running tasks: Essential container in task exited.
```

### Potential Causes & Resolutions

#### A. Architecture Mismatch (ARM64 vs. x86_64)
- **Cause:** Docker image was built on an ARM workstation (e.g. Apple Silicon Mac) without `--platform linux/amd64`, but the task definition specified `cpu_architecture = "X86_64"`. The task crashes immediately with `exec format error`.
- **Resolution:** Always build images with explicit platform target:
  ```powershell
  docker build --platform linux/amd64 -t <ecr_repo>:<tag> ./app
  ```

#### B. Missing Image in ECR
- **Cause:** ECS service was applied before the Docker image was pushed to ECR. Task fails with `CannotPullContainerError`.
- **Resolution:** Ensure the ECR repository is populated with the matching tag before running `terraform apply`.

#### C. Outbound Internet Connectivity Missing
- **Cause:** Tasks in private subnets cannot pull images from ECR or write logs to CloudWatch.
- **Resolution:** Confirm `nat_gateway_mode = "single"` and verify the private app route table has a `0.0.0.0/0` route pointing to the NAT Gateway ID.

---

## 2. PostgreSQL Database Connection Refused or SSL Error

### Symptoms
`GET /db-check` returns HTTP 500 or application logs show:
```text
psycopg2.OperationalError: connection to server at "...rds.amazonaws.com" failed: FATAL: no pg_hba.conf entry for host ..., SSL off
```

### Potential Causes & Resolutions

#### A. Forced SSL Requirement on PostgreSQL 15+
- **Cause:** AWS RDS PostgreSQL 15+ defaults `rds.force_ssl = 1`. Unencrypted connections are immediately rejected by the database.
- **Resolution:** In Python / Node / Go client connection strings, explicitly require SSL:
  ```python
  conn = psycopg2.connect(..., sslmode="require")
  ```

#### B. Security Group Ingress Misconfiguration
- **Cause:** RDS Security Group does not permit TCP 5432 from the ECS Task Security Group.
- **Resolution:** Verify standalone rule `aws_vpc_security_group_ingress_rule.rds_from_ecs` references `aws_security_group.ecs.id` as the source `referenced_security_group_id`.

#### C. Secrets Manager Secret Access Denied
- **Cause:** ECS task execution role lacks permissions to read the RDS master password.
- **Resolution:** Verify the execution role IAM policy grants `secretsmanager:GetSecretValue` on the exact master secret ARN:
  ```hcl
  resource "aws_iam_role_policy" "execution_secrets" {
    name = "ecs-execution-secrets-access"
    role = aws_iam_role.execution.id
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = [var.db_secret_arn]
      }]
    })
  }
  ```

---

## 3. ALB Target Group Health Check Failing (`Unhealthy`)

### Symptoms
ALB returns `HTTP 502 Bad Gateway` or `HTTP 503 Service Temporarily Unavailable`. AWS CLI shows:
```text
TargetHealth: { State: "unhealthy", Reason: "Target.FailedHealthChecks" }
```

### Potential Causes & Resolutions
- **Port Mismatch:** The ALB target group port does not match `var.container_port` (e.g. target group configured for 80, but container listens on 8000).
- **Grace Period Too Short:** Fargate container cold start takes 30–45 seconds, but `health_check_grace_period_seconds` is 0 or too short. Increase grace period to 60–120 seconds.
- **Path Error:** Health check path configured as `/` while the container only exposes `/health`. Confirm `health_check.path = "/health"`.

---

## 4. Teardown / Destroy Issues

### Symptoms
`terraform destroy` fails with `DependencyViolation: resource has active dependencies` or `VPC has dependencies and cannot be deleted`.

### Potential Causes & Resolutions

#### A. Lingering Elastic Network Interfaces (ENIs)
- **Cause:** AWS Fargate and ALB ENIs take 1–3 minutes to fully detach and release after the task/load balancer resource deletion completes.
- **Resolution:** Wait 60 seconds and re-run `terraform destroy`. AWS automatically de-allocates the ENIs once the ECS service and ALB have terminated.

#### B. Deletion Protection Enabled (Staging Environment)
- **Cause:** Staging RDS or ALB has `deletion_protection = true`. `terraform destroy` will fail with `InvalidParameterValue: Deletion protection is enabled`.
- **Resolution:** Follow the deliberate two-step teardown documented in `CLEANUP.md`:
  1. Set `deletion_protection = false` in `staging.tfvars`.
  2. Run `terraform apply -var-file=envs/staging.tfvars`.
  3. Re-run `terraform destroy -var-file=envs/staging.tfvars`.

---

## 5. Terraform S3 State Locking Errors

### Symptoms
```text
Error: Error acquiring the state lock
Lock Info:
  ID: ...
  Path: .../terraform.tfstate
```

### Potential Causes & Resolutions
- **Cause:** A previous plan or apply was interrupted (e.g. killed terminal session), leaving the state lock active in S3.
- **Resolution:**
  1. Confirm no active Terraform process is running.
  2. Run `terraform force-unlock <LOCK_ID>`.
