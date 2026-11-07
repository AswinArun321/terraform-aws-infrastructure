# Bootstrap Infrastructure

This directory contains the one-time setup Terraform configuration responsible for bootstrapping remote state storage and the container registry before provisioning workload environments.

## Resources Created

1. **Amazon S3 State Bucket:**
   - Server-side AES256 encryption enabled by default.
   - Versioning enabled for state history and disaster recovery.
   - All public access strictly blocked.
   - Bucket policy explicitly denying insecure (non-TLS) HTTP requests.
   - Non-current state versions automatically expired after 30 days.
   - `prevent_destroy = true` lifecycle guardrail.
   - Native state locking supported via `use_lockfile = true` (Terraform >= 1.10).

2. **Amazon ECR Repository:**
   - Scan-on-push enabled for automated vulnerability detection.
   - Tag immutability (`IMMUTABLE`) to prevent overwriting existing release tags.
   - Lifecycle policy retaining the last 10 images to control storage costs.

## Usage

```powershell
cd bootstrap
terraform init
terraform apply -var="project_name=tfinfra" -var="aws_region=us-east-1"
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `aws_region` | `string` | `"us-east-1"` | AWS region |
| `project_name` | `string` | `"tfinfra"` | Project naming prefix |
| `state_bucket_name` | `string` | `null` | Optional custom S3 bucket name |
| `ecr_repository_name` | `string` | `"tfinfra-app"` | ECR repository name |

## Outputs

| Name | Description |
|---|---|
| `state_bucket_name` | Name of the state S3 bucket |
| `state_bucket_arn` | ARN of the state S3 bucket |
| `ecr_repository_url` | URL used for `docker tag` and `docker push` |
| `ecr_repository_arn` | ARN of the ECR repository |
