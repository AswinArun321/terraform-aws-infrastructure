# AWS Infrastructure Teardown & Cleanup Guide

This document outlines the step-by-step procedures for safely destroying environments provisioned by this repository to avoid ongoing AWS charges.

---

## 1. Safety Principles

- **Never destroy without reviewing the plan:** Always generate a destroy plan (`-out=destroy.tfplan`) and inspect resources with `terraform show` before applying.
- **Teardown order:** Destroy workload environments (`dev`, `staging`) before destroying shared bootstrap state/ECR infrastructure.
- **Do not run destroy from automated pull-request workflows.**

---

## 2. Destroying Development Environment (`dev`)

Because `dev` has deletion protection disabled and `skip_final_snapshot = true`, it tears down cleanly in a single automated step:

```powershell
cd infra

# 1. Switch to dev backend
terraform init -backend-config=envs/dev.backend.hcl -reconfigure

# 2. Generate and inspect destroy plan
terraform plan -destroy -var-file=envs/dev.tfvars -out=dev-destroy.tfplan
terraform show dev-destroy.tfplan

# 3. Apply destroy plan (timed)
Measure-Command { terraform apply dev-destroy.tfplan } | Select-Object TotalMinutes, TotalSeconds
```

---

## 3. Destroying Staging Environment (`staging`)

In staging, **deletion protection** is enabled on RDS and ALB, and `skip_final_snapshot = false` by default. Attempting `terraform destroy` directly will fail with an error.

### Step 1: Temporarily Disable Deletion Protection
Edit `envs/staging.tfvars` or pass override variables:

```powershell
cd infra

# Initialize staging backend
terraform init -backend-config=envs/staging.backend.hcl -reconfigure

# Apply disabling of deletion protection and skip final snapshot (if snapshot is not needed)
terraform apply -var-file=envs/staging.tfvars `
  -var="db_deletion_protection=false" `
  -var="enable_deletion_protection_alb=false" `
  -var="db_skip_final_snapshot=true" `
  -auto-approve
```

### Step 2: Execute Destroy
```powershell
terraform plan -destroy -var-file=envs/staging.tfvars `
  -var="db_deletion_protection=false" `
  -var="enable_deletion_protection_alb=false" `
  -var="db_skip_final_snapshot=true" `
  -out=staging-destroy.tfplan

terraform apply staging-destroy.tfplan
```

---

## 4. Post-Teardown Verification Checklist

Run these AWS CLI commands to confirm zero lingering resources:

```powershell
# 1. Verify ECS Clusters and Services are terminated
aws ecs list-clusters

# 2. Verify Application Load Balancers are removed
aws elbv2 describe-load-balancers --query "LoadBalancers[].LoadBalancerName"

# 3. Verify NAT Gateways and Elastic IPs are released
aws ec2 describe-nat-gateways --filter "Name=state,Values=available,pending" --query "NatGateways[].NatGatewayId"
aws ec2 describe-addresses --query "Addresses[].PublicIp"

# 4. Verify RDS Database instances are deleted
aws rds describe-db-instances --query "DBInstances[].DBInstanceIdentifier"

# 5. Check for lingering manual snapshots (delete if no longer needed)
aws rds describe-db-snapshots --snapshot-type manual --query "DBSnapshots[].DBSnapshotIdentifier"

# 6. Verify VPCs are deleted
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=tfinfra" --query "Vpcs[].VpcId"
```

---

## 5. Teardown Bootstrap Infrastructure (Optional)

Once all environments (`dev` and `staging`) are destroyed and remote state is no longer required:

```powershell
cd bootstrap

# 1. Empty ECR repository images
$ecrRepo = terraform output -raw ecr_repository_name
aws ecr list-images --repository-name $ecrRepo --query "imageIds[*]" --output json | `
  aws ecr batch-delete-image --repository-name $ecrRepo --image-ids file:///dev/stdin

# 2. Delete state bucket objects & non-current versions
$bucket = terraform output -raw state_bucket_name
aws s3 rb s3://$bucket --force

# 3. Destroy bootstrap resources
terraform destroy -var="project_name=tfinfra" -var="aws_region=us-east-1"
```

---

## 6. AWS Billing Verification

Log in to the AWS Console the following morning and check:
1. **AWS Cost Explorer:** Verify that daily spend drops to $0.00.
2. **AWS Billing Dashboard:** Confirm no active hourly charges for NAT Gateways, ALBs, or Elastic IPs.

