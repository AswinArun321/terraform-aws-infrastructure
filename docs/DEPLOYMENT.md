# AWS Infrastructure Deployment Guide

This guide details the end-to-end process for deploying the AWS infrastructure from scratch using Terraform, pushing the demo application container to Amazon ECR, and switching between environments.

---

## Prerequisites

Ensure the following tools are installed and available on your system:
- **Terraform** >= 1.10.0 (`terraform version`)
- **AWS CLI** v2 (`aws --version`)
- **Docker** (`docker --version`)
- **Git** (`git --version`)
- An active AWS account with permissions to manage VPC, IAM, ALB, ECS, ECR, RDS, and Secrets Manager.

---

## Step 1: AWS Identity & Region Configuration

Authenticate using AWS IAM Identity Center (SSO) or short-lived credentials:

```powershell
# Configure and sign in with AWS SSO
aws configure sso --profile terraform-dev
aws sso login --profile terraform-dev
$env:AWS_PROFILE = "terraform-dev"

# Verify active identity and account ID
aws sts get-caller-identity
```

Export your target region (e.g., `us-east-1`):
```powershell
$env:AWS_DEFAULT_REGION = "us-east-1"
```

---

## Step 2: Bootstrap Infrastructure (Applied Once)

The `bootstrap/` configuration provisions:
- An Amazon S3 bucket for Terraform remote state with native locking (`use_lockfile = true`), encryption, versioning, and TLS-only bucket policy.
- An Amazon ECR repository for Docker images with tag immutability and scan-on-push.

```powershell
cd bootstrap

# 1. Initialize bootstrap with local state
terraform init

# 2. Review and apply bootstrap resources
terraform apply -var="project_name=tfinfra" -var="aws_region=us-east-1"

# 3. Note the generated outputs
$stateBucket = terraform output -raw state_bucket_name
$ecrRepoUrl  = terraform output -raw ecr_repository_url
Write-Host "State Bucket: $stateBucket"
Write-Host "ECR Repo:     $ecrRepoUrl"

cd ..
```

---

## Step 3: Build & Push Container Image to ECR

Build the demo application container for the target CPU architecture (`linux/amd64`), tag it with the git short SHA, and push to ECR:

```powershell
# 1. Get git commit SHA
$gitSha = (git rev-parse --short HEAD)

# 2. Authenticate Docker with Amazon ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ecrRepoUrl

# 3. Build container image
docker build --platform linux/amd64 -t "${ecrRepoUrl}:${gitSha}" ./app

# 4. Push to ECR repository
docker push "${ecrRepoUrl}:${gitSha}"
```

---

## Step 4: Configure Backend & Environment Variables

Copy the backend template files and set your actual S3 state bucket:

```powershell
cd infra

# Create backend config from template
Copy-Item envs/dev.backend.hcl.example envs/dev.backend.hcl
Copy-Item envs/staging.backend.hcl.example envs/staging.backend.hcl

# Edit envs/dev.backend.hcl and envs/staging.backend.hcl with the state bucket name:
# bucket       = "tfinfra-state-<account-id>"
# region       = "us-east-1"
# encrypt      = true
# use_lockfile = true
```

Ensure `envs/dev.tfvars` references your ECR repository URL and the image tag pushed in Step 3:
```hcl
image_repo_url = "<account-id>.dkr.ecr.us-east-1.amazonaws.com/tfinfra-app"
image_tag      = "<git-sha>"
```

---

## Step 5: Provision Development Environment (`dev`)

Initialize Terraform with the dev backend configuration and apply:

```powershell
# 1. Initialize root configuration with dev backend
terraform init -backend-config=envs/dev.backend.hcl -reconfigure

# 2. Validate configuration syntax and modules
terraform fmt -check -recursive
terraform validate

# 3. Generate execution plan
terraform plan -var-file=envs/dev.tfvars -out=dev.tfplan

# 4. Apply timed execution plan
Measure-Command { terraform apply dev.tfplan } | Select-Object TotalMinutes, TotalSeconds
```

---

## Step 6: Post-Deployment Verification

Query outputs and test application endpoints:

```powershell
# Fetch ALB DNS hostname
$albDns = terraform output -raw alb_dns_name
Write-Host "Application URL: http://$albDns"

# Test health endpoint (no DB dependency)
curl.exe -i "http://$albDns/health"

# Test database connectivity endpoint (runs SELECT 1 over TLS)
curl.exe -i "http://$albDns/db-check"

# Inspect ECS Service status
aws ecs describe-services `
  --cluster (terraform output -raw ecs_cluster_name) `
  --services (terraform output -raw ecs_service_name) `
  --query "services[0].{Status:status,Desired:desiredCount,Running:runningCount}"

# Confirm RDS is private and encrypted
aws rds describe-db-instances `
  --query "DBInstances[?DBInstanceIdentifier=='tfinfra-dev-pg'].{Id:DBInstanceIdentifier,Public:PubliclyAccessible,Encrypted:StorageEncrypted}"
```

---

## Step 7: Application Updates & Rollbacks

To deploy a new version of the application:
1. Build and push the new container image with its new commit SHA:
   ```powershell
   $newSha = (git rev-parse --short HEAD)
   docker build --platform linux/amd64 -t "${ecrRepoUrl}:${newSha}" ./app
   docker push "${ecrRepoUrl}:${newSha}"
   ```
2. Update `image_tag = "<newSha>"` in `envs/dev.tfvars`.
3. Run `terraform apply -var-file=envs/dev.tfvars`.
   - ECS Fargate performs a rolling deployment with zero downtime.
   - If health checks fail, the deployment circuit breaker automatically rolls back to the previous stable task definition.

---

## Step 8: Deploying Staging Environment (`staging`)

Deploying staging uses the exact same `infra/` codebase with the staging selector:

```powershell
# Switch backend to staging state
terraform init -backend-config=envs/staging.backend.hcl -reconfigure

# Plan and apply staging
terraform plan -var-file=envs/staging.tfvars -out=staging.tfplan
terraform apply staging.tfplan
```

