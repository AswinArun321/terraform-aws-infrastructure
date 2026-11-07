# AWS Infrastructure Provisioning with Terraform — Completion Plan (v2)

**Repository:** https://github.com/AswinArun321/terraform-aws-infrastructure  
**Default branch:** `master`  
**Target:** Reusable Terraform modules that provision an isolated `dev` and `staging` AWS environment (VPC, subnets, security groups, ECS Fargate, ALB, private RDS PostgreSQL) from one root configuration, switched by one environment selector.

---

## 0. Where the project actually stands

Audit of the public repository (checked 7 Nov 2026):

| Item | Finding |
|---|---|
| Commits | 2 |
| Files | `README.md` only |
| Terraform code | **None.** No `.tf` files, modules, environments, backend or workflows |
| Repo metadata | No description, topics or license |
| README | Describes a structure that does not exist; states "under 10 minutes" and "multi-hour manual process" as completed results; contains placeholders (`<repository-name>`, "Add your LinkedIn profile here") |

**Consequences for this plan**

1. The old "Phase 0: audit the repo" is finished. It is replaced by a short *repo hygiene* phase.
2. Everything in this project is still to be built. Until a timed, successful apply exists, the README and resume bullets must not present the performance and environment claims as facts.
3. Build order matters more than before, because there is no existing code to adapt.

---

## 1. What changed from the previous plan, and why

| # | Previous plan | This plan | Reason |
|---|---|---|---|
| 1 | Phase 0 = audit unknown repo | Audit done (above); Phase 0 = hygiene + README correction | Repo is README-only; the README currently makes unverified claims |
| 2 | Separate `environments/dev` and `environments/staging`, each with its own `main.tf` | **One** root config (`infra/`) + `envs/dev.tfvars` / `envs/staging.tfvars` + per-env backend files | Duplicated `main.tf` files contradict the resume claim ("same configuration… single variable change") and drift over time |
| 3 | ECS phase before ALB phase | ALB before ECS service | The ECS service needs the target group ARN; the old order creates a dependency problem |
| 4 | Separate `iam` module | IAM roles live inside the `ecs` module | Roles exist only to serve the task; fewer modules, fewer cross-module cycles |
| 5 | Separate SG module referenced by ALB/ECS/RDS but rules described inline | One `security-groups` module using standalone `aws_vpc_security_group_*_rule` resources | Avoids circular SG references |
| 6 | Locking "per the supported mechanism" | `use_lockfile = true` (S3-native locking, Terraform ≥ 1.10); no DynamoDB table | DynamoDB locking is deprecated and slated for removal; native locking needs no extra resource |
| 7 | DB secret "reference/generation strategy" left open | `manage_master_user_password = true` (RDS-managed secret in Secrets Manager) | No password in Terraform code, tfvars or state |
| 8 | NAT vs VPC endpoints left open | **Decision:** one NAT Gateway for dev (variable-controlled), destroy the same day | Interface endpoints for ECR/logs/S3 cost more than a short-lived NAT and add many resources |
| 9 | ECR chicken-and-egg not addressed | ECR repo created in `bootstrap/` before any ECS service exists | ECS cannot start tasks until an image exists |
| 10 | CI in Phase 9 (after everything) | CI checks right after the skeleton exists (Phase 3) | Catches errors from the first module onward |
| 11 | Deploy via OIDC, least-privilege deployer role, HTTPS, autoscaling, dashboards, SNS all in the main path | Moved to **Stretch** tier | They do not back any current resume claim and would delay a working demo |
| 12 | Dev and staging implicitly run at once | Sequential by default: deploy → verify → destroy → next env | Halves cost; both stacks together only for a short isolation proof |
| 13 | `aws configure` while saying "prefer SSO" | `aws configure sso` + `aws sso login` | Removes long-lived keys on disk |
| 14 | "Never paste keys into ChatGPT" | "Never paste credentials into any chat, AI tool, issue or commit" | Applies to every tool |
| 15 | Phase headings and execution table used different numbering | One consistent numbering | Avoids confusion |
| 16 | No timing method | `Measure-Command` runs, repeated 3 times, per-resource timings recorded | Needed to back or correct the "under 10 minutes" claim |
| 17 | `tfsec` | Trivy config scan (tfsec's successor) and/or Checkov | tfsec is folded into Trivy |
| 18 | `git add .` | Add explicit paths and review the diff | Prevents committing state or tfvars by accident |
| 19 | Missing practical gotchas | Added Section 14 (image architecture, forced SSL on PG15+, ENI delays on destroy, name-length limits, etc.) | These are the usual reasons first applies fail |

---

## 2. Scope tiers

**Tier A — Must (backs the resume claims)**
- Modules: `vpc`, `security-groups`, `alb`, `rds`, `ecs`
- Remote S3 state with versioning, encryption, locking, separate key per environment
- Same root config deploys `dev` and `staging` via one selector
- One real, timed, successful `terraform apply` per environment, then destroy
- README that reports only what was measured

**Tier B — Should (portfolio quality)**
- GitHub Actions PR checks (fmt, validate, TFLint, Trivy/Checkov, secret scan)
- Architecture diagram, cost estimate, deployment/cleanup docs
- Small demo app (`/health`, `/db-check`) in private ECR

**Tier C — Stretch (only after A and B)**
- HTTPS with ACM + Route 53 domain
- GitHub OIDC deploy workflow with environment approval
- Scoped least-privilege Terraform deployer role
- ECS autoscaling, CloudWatch dashboard, SNS alarms
- Per-AZ NAT gateways, Multi-AZ RDS
- `terraform test` for modules

---

## 3. Key design decisions

| Topic | Decision |
|---|---|
| Terraform version | `required_version = ">= 1.10"` (needed for `use_lockfile`) |
| AWS provider | Pin to the current major with `~>` (check `terraform init` output and pin the exact minor you tested) |
| Environment selector | `-var-file=envs/<env>.tfvars` plus `-backend-config=envs/<env>.backend.hcl`; `var.environment` validated to `dev` or `staging` |
| Why not workspaces | Workspaces share one backend config and make it easy to apply to the wrong environment without noticing; explicit backend files are clearer |
| State | One S3 bucket, keys `dev/terraform.tfstate` and `staging/terraform.tfstate`, `use_lockfile = true`, `encrypt = true` |
| Egress for private tasks | Single NAT Gateway, controlled by a variable (`single` / `none`) |
| Database secret | RDS-managed master password; ECS reads it through the task definition `secrets` block |
| Image | Demo app in private ECR, tagged with the git short SHA (never `latest`) |
| Fargate platform | Explicit `runtime_platform` (`X86_64` unless you build on ARM and choose `ARM64`) |
| Sizing (dev) | Smallest Fargate size, a burstable small RDS class, 20 GB storage, single-AZ. Confirm against current pricing before applying |
| Tags | `default_tags` in the provider: `Project`, `Environment`, `ManagedBy = terraform` |
| Subnets | Computed with `cidrsubnet()`; AZs from `aws_availability_zones` data source (no hand-typed lists) |

---

## 4. Target architecture

```text
                          Internet
                             |
                    Application Load Balancer
                       (public subnets, 2 AZs)
                       /                 \
                    AZ-a                 AZ-b
                      |                    |
               ECS Fargate task     ECS Fargate task
              (private app subnet) (private app subnet)
                      \                    /
                       \                  /
                        RDS PostgreSQL (private DB subnets)

   Private app subnets -> NAT Gateway (public subnet) -> Internet Gateway
   (image pulls from ECR, CloudWatch Logs, Secrets Manager)
```

Traffic rules:
1. Internet → ALB on HTTP 80 (HTTPS is Tier C).
2. ALB → ECS tasks on the app port only, via an IP-type target group.
3. ECS tasks → RDS on TCP 5432 only.
4. RDS has no public access and accepts traffic only from the ECS task security group.
5. Tasks have no public IP; outbound goes through NAT.

---

## 5. Safety and cost rules

- Do not run `terraform apply` until account, region, budget, plan and expected cost are reviewed.
- Never commit credentials, state files, saved plans (`*.tfplan`), `.terraform/`, private keys or `*.backend.hcl` containing real account values.
- Never paste credentials into any chat, AI tool, issue or commit.
- Use IAM Identity Center (SSO) or short-lived credentials. Do not use the root account for work. Enable MFA.
- Create an AWS Budget with email alerts **before** the first apply.
- Keep RDS private. Never open 5432 to `0.0.0.0/0`.
- Deploy dev first. Do not create staging until dev is verified.
- Destroy each environment the same day unless there is a reason not to.
- Saved plans can contain sensitive values: do not upload them as CI artifacts or share them.
- Costs that continue or surprise: ALB hours, NAT Gateway hours and data processing, public IPv4 addresses, RDS instance and storage, retained snapshots, CloudWatch logs, ECR storage, data transfer.

---

## 6. Repository structure (target)

```text
terraform-aws-infrastructure/
├── README.md
├── plan.md
├── LICENSE
├── .gitignore
├── .tflint.hcl
├── bootstrap/                  # applied once, local state first then migrated
│   ├── main.tf                 # state bucket + ECR repository
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
├── infra/                      # the ONE root configuration
│   ├── versions.tf
│   ├── backend.tf              # partial: backend "s3" {} only
│   ├── providers.tf
│   ├── main.tf                 # wires the modules together
│   ├── variables.tf
│   ├── outputs.tf
│   └── envs/
│       ├── dev.tfvars          # non-secret, committed
│       ├── staging.tfvars      # non-secret, committed
│       ├── dev.backend.hcl.example
│       └── staging.backend.hcl.example
├── modules/
│   ├── vpc/
│   ├── security-groups/
│   ├── alb/
│   ├── rds/
│   └── ecs/                    # cluster, task definition, service, IAM roles, log group
├── app/                        # tiny demo service
│   ├── Dockerfile
│   └── (source with /health and /db-check)
├── .github/workflows/
│   └── terraform-checks.yml
└── docs/
    ├── ARCHITECTURE.md
    ├── COST-ESTIMATE.md
    ├── DEPLOYMENT.md
    ├── EVIDENCE.md             # timings, screenshots, command output
    ├── TROUBLESHOOTING.md
    └── CLEANUP.md
```

Every module gets `main.tf`, `variables.tf`, `outputs.tf` and a short README (inputs, outputs, responsibility). `envs/*.tfvars` contain no secrets, so they can be committed; that is what makes the single-variable environment switch visible in the repo.

---

## Phase 0 — Repo hygiene and honest README (no AWS)

**Branch:** `docs/readme-correction`

- [ ] Add `.gitignore`: `.terraform/`, `*.tfstate*`, `*.tfplan`, `crash.log`, `*.backend.hcl`, `.env`, `*.pem`, `.DS_Store`.
- [ ] Add a `LICENSE` (MIT is typical for portfolio code).
- [ ] Set the GitHub repo description and topics (`terraform`, `aws`, `ecs-fargate`, `alb`, `rds`, `infrastructure-as-code`).
- [ ] Fix the README:
  - Replace the structure tree with the real one (or the Section 6 target marked "planned").
  - Move "under 10 minutes" and "multi-hour manual process" out of *Project Outcome* into a **Status** section: "Target — to be measured".
  - Fix `git clone` URL and the LinkedIn placeholder.
  - State that dev/staging selection will use per-environment var and backend files.
- [ ] Copy this `plan.md` into the repo.

**Exit:** README makes no claim that the repo cannot yet back up.

---

## Phase 1 — AWS account, identity and cost guardrails

- [ ] Choose the account and region; record both.
- [ ] Enable MFA. Use IAM Identity Center (or an admin role with MFA) for local work.
- [ ] Configure SSO and verify identity:

```powershell
aws configure sso --profile terraform-dev
aws sso login --profile terraform-dev
$env:AWS_PROFILE = "terraform-dev"
aws sts get-caller-identity
```

- [ ] Create an AWS Budget with email alerts (set a low monthly limit appropriate for a learning account).
- [ ] Look up current pricing for ALB, NAT Gateway, Fargate, RDS and public IPv4 in your region using the AWS Pricing Calculator. Do not assume free tier covers this stack.
- [ ] Pick a naming prefix (e.g. `tfinfra`), keeping ALB and target-group names within 32 characters.
- [ ] Find a supported PostgreSQL version for your region:

```powershell
aws rds describe-db-engine-versions --engine postgres --query "DBEngineVersions[].EngineVersion"
```

- [ ] Fill `docs/COST-ESTIMATE.md` (region, sizes, planned runtime, assumptions).

**Exit:** Identity and region verified, budget alert active, cost assumptions written down.

---

## Phase 2 — Bootstrap (state bucket + ECR) and root skeleton

**Branch:** `feat/foundation`

Bootstrap (`bootstrap/`, applied once):
- [ ] S3 bucket named with the account ID for uniqueness; versioning on; default encryption; all public access blocked; bucket policy denying non-TLS requests; lifecycle rule expiring old noncurrent versions; `prevent_destroy = true`.
- [ ] ECR repository: scan on push, immutable tags, lifecycle policy keeping the last ~10 images.
- [ ] Apply with local state, then add an S3 backend block and run `terraform init -migrate-state` so bootstrap state is also protected.

Root skeleton (`infra/`):
- [ ] `versions.tf` with `required_version = ">= 1.10"` and pinned AWS provider.
- [ ] `backend.tf` containing an empty `backend "s3" {}`; real values supplied at init:

```hcl
# infra/envs/dev.backend.hcl  (gitignored; commit only the .example)
bucket       = "<state-bucket-name>"
key          = "dev/terraform.tfstate"
region       = "<region>"
encrypt      = true
use_lockfile = true
```

```powershell
cd infra
terraform init -backend-config=envs/dev.backend.hcl -reconfigure
```

- [ ] Variables: `project_name`, `environment` (validated), `aws_region`, sizing inputs. Provider `default_tags`.
- [ ] Confirm `terraform fmt`, `validate` and an empty `plan` work.
- [ ] Verify the lock: start a plan in one terminal and a second plan in another; the second should report a lock.

**Exit:** Backend works with locking; dev and staging have different state keys; no state or secrets committed.

---

## Phase 3 — CI checks (early)

**Branch:** `ci/terraform-checks`

`terraform-checks.yml` on pull requests:
- [ ] `terraform fmt -check -recursive`
- [ ] `terraform init -backend=false` and `terraform validate` for `infra/` and `bootstrap/`
- [ ] TFLint
- [ ] Trivy config scan and/or Checkov
- [ ] Secret scan (e.g. gitleaks)
- [ ] Pin third-party actions to a version tag or commit SHA; use `permissions: contents: read`.
- [ ] Mark the checks as required for merging to `master`.

No AWS credentials in this workflow. Add findings you intentionally accept to a documented ignore list with a reason.

**Exit:** A PR with a badly formatted file fails; a clean PR passes.

---

## Phase 4 — VPC module

**Branch:** `feat/vpc`

- [ ] VPC with DNS support and hostnames.
- [ ] Public, private-app and private-db subnets in 2 AZs (CIDRs from `cidrsubnet`).
- [ ] Internet Gateway; public route table.
- [ ] NAT Gateway + Elastic IP controlled by `nat_gateway_mode` (`single` or `none`); private-app route table points to it.
- [ ] DB subnets: route table with **no** internet route.
- [ ] Outputs: VPC ID, subnet ID lists per tier, VPC CIDR.

Validation: [ ] CIDRs don't overlap; [ ] subnets span two AZs; [ ] DB tier has no `0.0.0.0/0` route.

Tip: VPC, subnets, route tables and security groups are free, so you may apply them early with `nat_gateway_mode = "none"` to catch mistakes cheaply. Paid resources wait for the timed run.

---

## Phase 5 — Security groups module

**Branch:** `feat/security-groups`

Use standalone `aws_vpc_security_group_ingress_rule` / `egress_rule` resources.

| Group | Ingress | Egress |
|---|---|---|
| ALB | 80 from allowed CIDRs (default `0.0.0.0/0` for the demo) | app port → ECS SG |
| ECS tasks | app port from **ALB SG** | 5432 → RDS SG; 443 → `0.0.0.0/0` (ECR, logs, Secrets Manager via NAT) |
| RDS | 5432 from **ECS SG** | none needed |

- [ ] Service-to-service rules reference security groups, not CIDRs.
- [ ] Every rule has a description.

---

## Phase 6 — ALB module

**Branch:** `feat/alb`

- [ ] Internet-facing ALB across both public subnets.
- [ ] Target group: `target_type = "ip"`, health check path `/health`, port matching the container.
- [ ] HTTP :80 listener forwarding to the target group.
- [ ] `drop_invalid_header_fields = true`; `deletion_protection = false` for dev (variable).
- [ ] Outputs: DNS name, ARN, target group ARN, listener ARN.
- [ ] Do not claim HTTPS (Tier C).

---

## Phase 7 — RDS module

**Branch:** `feat/rds`

- [ ] DB subnet group on private DB subnets.
- [ ] PostgreSQL instance: `publicly_accessible = false`, `storage_encrypted = true`, `manage_master_user_password = true`, RDS SG attached.
- [ ] Variables: engine version, instance class, allocated storage, db name, username, backup retention, `multi_az`, `deletion_protection`, `skip_final_snapshot`.
- [ ] Dev: short backup retention, `skip_final_snapshot = true`, `deletion_protection = false`.
- [ ] Staging: longer retention, final snapshot on, deletion protection on. Cleanup then needs a deliberate two-step (set protection false, apply, destroy); document it in `CLEANUP.md`.
- [ ] Outputs: endpoint, port, db name, **master secret ARN**. No password output.

---

## Phase 8 — ECS Fargate module and demo app

**Branch:** `feat/ecs` (module) and `feat/demo-app` (app)

Demo app (`app/`):
- [ ] Endpoints: `GET /health` (no DB dependency) and `GET /db-check` (runs `SELECT 1`, returns only ok/fail).
- [ ] Connect to PostgreSQL with TLS required (PostgreSQL 15+ on RDS forces SSL by default).
- [ ] Log to stdout; never log credentials.
- [ ] Build for the platform you declared in the task definition, then push:

```powershell
docker build --platform linux/amd64 -t <ecr-repo-url>:<git-sha> app
aws ecr get-login-password | docker login --username AWS --password-stdin <registry-host>
docker push <ecr-repo-url>:<git-sha>
```

ECS module:
- [ ] Cluster, log group with explicit retention, task execution role, task role (empty or minimal).
- [ ] Execution role: ECR pull, log writes, `secretsmanager:GetSecretValue` on the RDS secret ARN only.
- [ ] Task definition: Fargate, smallest valid CPU/memory, explicit `runtime_platform`, `awslogs` driver, non-secret env vars (host, port, db name), `secrets` entries pointing at the RDS secret (e.g. `<secret_arn>:password::`).
- [ ] Service: private app subnets, `assign_public_ip = false`, ECS SG, attached to the ALB target group, `health_check_grace_period_seconds` set, deployment circuit breaker with rollback.
- [ ] Variables: `image_tag`, `desired_count`, `cpu`, `memory`, `container_port`.
- [ ] Outputs: cluster name, service name, task definition ARN.

---

## Phase 9 — Compose the root config and run dev (timed)

**Branch:** `feat/environments`

Wire all modules in `infra/main.tf`, then create `envs/dev.tfvars` and `envs/staging.tfvars`. Differences live only in tfvars:

| Setting | Dev | Staging |
|---|---|---|
| `environment` | `dev` | `staging` |
| VPC CIDR | distinct from staging | distinct from dev |
| ECS desired count | 1 | 1–2 |
| RDS class / storage | smallest suitable | sized for test workload |
| Backup retention | short | longer |
| Deletion protection | off | on |
| Final snapshot | skipped | taken |
| NAT | single | single |

Pre-apply checklist:
- [ ] `aws sts get-caller-identity` shows the intended account.
- [ ] Budget alert active; cost estimate reviewed.
- [ ] Image exists in ECR with the tag you pass.
- [ ] `plan` shows only dev resources and no unexpected replacements or destroys.
- [ ] RDS private and encrypted in plan; SG rules as designed.

```powershell
cd infra
terraform init -backend-config=envs/dev.backend.hcl -reconfigure
terraform fmt -check -recursive
terraform validate
terraform plan -var-file=envs/dev.tfvars -out=dev.tfplan
terraform show dev.tfplan
```

Timed apply (do not use `-auto-approve` the first time):

```powershell
Measure-Command { terraform apply dev.tfplan } | Select-Object TotalMinutes
```

Also record the per-resource "Creation complete after …" lines from the output. RDS is normally the slowest item, so treat "under 10 minutes" as a hypothesis to measure, not a given.

Verify:

```powershell
$alb = terraform output -raw alb_dns_name
curl.exe -i "http://$alb/health"
curl.exe -i "http://$alb/db-check"
aws ecs describe-services --cluster <cluster> --services <service> --query "services[0].{running:runningCount,desired:desiredCount,events:events[0].message}"
aws elbv2 describe-target-health --target-group-arn <tg-arn>
aws rds describe-db-instances --query "DBInstances[].{id:DBInstanceIdentifier,public:PubliclyAccessible,enc:StorageEncrypted}"
```

- [ ] Service steady; targets healthy; `/health` and `/db-check` succeed.
- [ ] RDS not public and encrypted.
- [ ] Logs visible in CloudWatch with no credentials.
- [ ] Repeat the timed cycle (destroy, then apply) **3 times** and record min / median / max for apply and destroy.

Then destroy dev (Phase 11) unless you need it for the next step.

---

## Phase 10 — Staging

Only after dev is verified and cost is acceptable:

```powershell
terraform init -backend-config=envs/staging.backend.hcl -reconfigure
terraform plan -var-file=envs/staging.tfvars -out=staging.tfplan
```

- [ ] Plan contains staging resources only and uses the staging state key.
- [ ] Apply, then run the same verification as dev.
- [ ] Confirm backups and deletion protection.
- [ ] Optional isolation proof (short window): have dev and staging up together, plan each, and show neither plan touches the other's resources.
- [ ] Document environment differences.

**Exit:** One config, two environments, separate states, one selector.

---

## Phase 11 — Operations lite and cleanup

Minimum operational readiness (Tier B):
- [ ] Log retention set on every log group.
- [ ] One CloudWatch alarm for unhealthy targets (optional SNS email).
- [ ] `DEPLOYMENT.md` (including rollback by redeploying a previous `image_tag`), `TROUBLESHOOTING.md`, `CLEANUP.md`.

Cleanup per environment, from `infra/` with that environment's backend and var-file:

```powershell
terraform plan -destroy -var-file=envs/dev.tfvars -out=destroy.tfplan
terraform show destroy.tfplan
Measure-Command { terraform apply destroy.tfplan } | Select-Object TotalMinutes
```

Verify afterwards:
- [ ] ECS service/tasks, ALB, target group gone.
- [ ] NAT Gateway and Elastic IP gone.
- [ ] RDS instance gone; snapshots understood and deleted if not needed.
- [ ] Security groups, subnets, VPC gone (if stuck, see Troubleshooting: lingering ENIs).
- [ ] CloudWatch log groups, ECR images, noncurrent state versions reviewed.
- [ ] Cost Explorer checked the next day.

Do not delete the state bucket or ECR repo until both environments are destroyed and the state is no longer needed. Never run destroy from a PR workflow.

---

## Phase 12 — Documentation and evidence

README sections: overview, status, architecture diagram, modules, repo structure, prerequisites, cost warning, bootstrap, deploy dev, deploy staging (the one-selector commands), CI, security controls, measured results, cleanup, limitations, future work.

`docs/EVIDENCE.md` should contain:
- [ ] Output of `terraform apply` timings (3 runs) with date, region, sizes and whether NAT/RDS settings were used.
- [ ] `terraform plan` for dev and staging showing different state keys.
- [ ] Screenshots or CLI output: healthy targets, `/health` and `/db-check` responses, RDS `PubliclyAccessible = false`.
- [ ] CI run showing passing checks.
- [ ] Destroy output and a clean-up confirmation.
- [ ] Rough actual cost for the test sessions.

---

## 13. Git workflow

```powershell
git checkout master
git pull origin master
git checkout -b feat/vpc
# work, then:
git status
git diff
git add modules/vpc infra/main.tf
git commit -m "feat(vpc): add reusable VPC module"
git push -u origin feat/vpc
```

Open a PR to `master`, wait for the Phase 3 checks, and review the plan output before merging. Suggested branches: `docs/readme-correction`, `feat/foundation`, `ci/terraform-checks`, `feat/vpc`, `feat/security-groups`, `feat/alb`, `feat/rds`, `feat/ecs`, `feat/demo-app`, `feat/environments`, `docs/evidence`.

Before every push: confirm `git status` shows no `*.tfstate`, `*.tfplan`, `.terraform/`, `*.backend.hcl` or credentials.

---

## 14. Common pitfalls to check up front

- **Image architecture mismatch:** an image built for the wrong CPU architecture makes tasks fail at start. Match `runtime_platform` to your `docker build --platform`.
- **Forced SSL on PostgreSQL 15+:** connections without TLS are rejected; make the app require SSL.
- **Target group port/path mismatch:** health checks fail and ECS keeps replacing tasks. Check port, path and grace period.
- **No egress from private subnets:** tasks cannot pull from ECR or send logs unless NAT (or endpoints) exist and route tables point to them.
- **Image not yet in ECR:** service stays at 0 running tasks.
- **Name limits:** ALB and target group names ≤ 32 chars; S3 bucket names are global; RDS identifiers are lowercase.
- **Deletion protection:** staging RDS will block destroy until you turn it off and apply that change.
- **Lingering ENIs:** subnets and security groups can take minutes to delete after ECS/ALB removal; retry destroy before investigating.
- **`terraform.tfvars` auto-loads, `envs/*.tfvars` does not:** always pass `-var-file`.
- **Wrong environment:** after switching, always re-run `init -backend-config=… -reconfigure` and read the plan header and resource names before applying.
- **Secrets in outputs/logs:** mark any sensitive output `sensitive = true`, and never output the DB credentials.

---

## 15. Resume claims and accuracy

The original bullets stay as targets until evidence exists. Suggested handling:

| Claim | Condition to keep it | If the measurement disagrees |
|---|---|---|
| Modules for VPC, subnets, SGs, ECS Fargate, ALB, RDS PostgreSQL | All five modules applied successfully | Remove what was not built |
| "Reduced setup from a multi-hour manual console process" | You have a timed manual baseline, or you word it as an estimate ("estimated several hours") | Drop the comparison and keep only the automated time |
| "Single `terraform apply` under 10 minutes" | Median of your timed runs is under 10 min with conditions recorded | Use the measured figure, e.g. "about N minutes" |
| "Remote state" | S3 backend with locking in use | — |
| "Same configuration provisions dev and staging with a single variable change" | Both environments applied from the same `infra/` code using only a different var-file/backend file | State accurately: "one config, per-environment var and backend files" |

Possible final wording (fill the brackets only after measuring):

> Built Terraform modules provisioning a VPC, subnets, security groups, ECS Fargate service, ALB and private RDS PostgreSQL; full environment applies in ~[N] minutes (median of 3 runs).  
> Used S3 remote state with native locking and per-environment var files so one root configuration deploys isolated dev and staging environments; added GitHub Actions fmt/validate/security checks.

---

## 16. Definition of done

**Tier A**
- [ ] `vpc`, `security-groups`, `alb`, `rds`, `ecs` modules implemented and reusable
- [ ] ECS service steady; ALB targets healthy; `/db-check` succeeds
- [ ] RDS private, encrypted, reachable only from ECS; no password in code, tfvars, outputs or logs
- [ ] S3 state with versioning, encryption, locking; separate keys per environment
- [ ] Dev and staging each deployed from the same `infra/` code via var-file + backend file
- [ ] Apply and destroy timed (3 runs) and recorded
- [ ] Both environments destroyed and billing checked

**Tier B**
- [ ] CI checks pass and are required on `master`
- [ ] No unresolved IaC scanner findings (or documented exceptions)
- [ ] README, diagram, cost estimate, deployment, troubleshooting and cleanup docs complete
- [ ] `EVIDENCE.md` populated
- [ ] README and resume match the measured facts

**Tier C (optional)**
- [ ] HTTPS, OIDC deploy workflow, scoped deployer role, autoscaling, dashboards, `terraform test`

---

## 17. Execution order

| Order | Phase | Result |
|---:|---|---|
| 1 | 0 — Repo hygiene, honest README | Safe repo, no unverified claims |
| 2 | 1 — AWS identity and budget | Safe account |
| 3 | 2 — Bootstrap and root skeleton | State bucket, ECR, working backend |
| 4 | 3 — CI checks | Automated feedback from the start |
| 5 | 4 — VPC | Network tiers |
| 6 | 5 — Security groups | Least-privilege network rules |
| 7 | 6 — ALB | Public entry point |
| 8 | 7 — RDS | Private database |
| 9 | 8 — ECS + demo app | Running service |
| 10 | 9 — Dev apply (timed) | Verified environment and timings |
| 11 | 10 — Staging apply | Second isolated environment |
| 12 | 11 — Ops lite and cleanup | Cost-safe teardown |
| 13 | 12 — Docs and evidence | Portfolio-ready project |

**Start with Phase 0.** Do not create AWS resources until Phase 1 (budget and identity) is complete, and do not run the first paid `apply` until the Phase 9 checklist is satisfied.
