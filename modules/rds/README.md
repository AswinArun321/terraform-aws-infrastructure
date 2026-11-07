# RDS PostgreSQL Terraform Module

This module provisions a private, secure Amazon RDS PostgreSQL database instance.

## Security & Architecture Highlights

- **Complete Air-Gap:** Placed exclusively inside `private_db` subnets with `publicly_accessible = false`.
- **At-Rest Storage Encryption:** KMS encryption enabled with `storage_encrypted = true` on `gp3` storage.
- **Zero Credentials in Code or State:** Uses `manage_master_user_password = true`. AWS automatically generates the master password, manages rotation, and stores credentials in AWS Secrets Manager.
- **Environment Adaptability:**
  - `dev`: Single-AZ, short backup retention, `skip_final_snapshot = true`, `deletion_protection = false`.
  - `staging`: Extended backup retention, final snapshot taken on destroy, `deletion_protection = true`.

## Usage

```hcl
module "rds" {
  source                  = "../modules/rds"
  project_name            = "tfinfra"
  environment             = "dev"
  private_db_subnet_ids   = module.vpc.private_db_subnet_ids
  rds_security_group_id   = module.security_groups.rds_security_group_id
  instance_class          = "db.t4g.micro"
  allocated_storage       = 20
  backup_retention_period = 1
  deletion_protection     = false
  skip_final_snapshot     = true
}
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `project_name` | `string` | — | Project naming identifier |
| `environment` | `string` | — | Target environment (`dev` or `staging`) |
| `private_db_subnet_ids` | `list(string)` | — | Private database subnets |
| `rds_security_group_id` | `string` | — | Security group ID for RDS |
| `engine_version` | `string` | `"16.3"` | PostgreSQL version |
| `instance_class` | `string` | `"db.t4g.micro"` | RDS instance class |
| `allocated_storage` | `number` | `20` | Storage in GiB |
| `db_name` | `string` | `"appdb"` | Initial database name |
| `db_username` | `string` | `"dbadmin"` | Master username |
| `backup_retention_period` | `number` | `1` | Automated backup retention (days) |
| `multi_az` | `bool` | `false` | Multi-AZ deployment flag |
| `deletion_protection` | `bool` | `false` | Prevent accidental drop |
| `skip_final_snapshot` | `bool` | `true` | Skip snapshot before destroy |

## Outputs

| Name | Description |
|---|---|
| `endpoint` | Hostname:port endpoint |
| `address` | Hostname address |
| `port` | Database port (5432) |
| `db_name` | Database name |
| `master_user_secret_arn` | Secrets Manager secret ARN for the master password |
