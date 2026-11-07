# Demo Application Service

A lightweight, production-ready Python service used to demonstrate and verify the AWS infrastructure stack.

## Endpoints

- `GET /`: Service metadata.
- `GET /health`: Fast, stateless health check endpoint used by the Application Load Balancer target group. Returns HTTP 200.
- `GET /db-check`: End-to-end database connectivity check that executes `SELECT version();` over TLS (`sslmode="require"`) against Amazon RDS PostgreSQL.

## Environment Variables

| Variable | Description |
|---|---|
| `APP_ENV` | Environment name (`dev` or `staging`) |
| `PORT` | Listening port (default: 8000) |
| `DB_HOST` | RDS PostgreSQL hostname |
| `DB_PORT` | RDS PostgreSQL port (default: 5432) |
| `DB_NAME` | RDS Database name |
| `DB_USER` | RDS Master username |
| `DB_PASSWORD` | Injected securely by ECS from AWS Secrets Manager |

## Local Build & Run

```bash
docker build --platform linux/amd64 -t tfinfra-app:local .
docker run -p 8000:8000 tfinfra-app:local
```
