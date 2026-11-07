import logging
import os
import sys
from fastapi import FastAPI, HTTPException, status
from fastapi.responses import JSONResponse
import psycopg2

# Configure structured logging to stdout
logging.basicConfig(
    stream=sys.stdout,
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)
logger = logging.getLogger("demo-app")

app = FastAPI(
    title="AWS Terraform Infrastructure Demo App",
    version="1.0.0",
    docs_url=None,
    redoc_url=None
)

APP_ENV = os.getenv("APP_ENV", "dev")
DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "appdb")
DB_USER = os.getenv("DB_USER", "dbadmin")
DB_PASSWORD = os.getenv("DB_PASSWORD")


@app.get("/")
def read_root():
    """Root endpoint providing service metadata."""
    return {
        "service": "terraform-aws-infrastructure-demo",
        "environment": APP_ENV,
        "endpoints": ["/health", "/db-check"]
    }


@app.get("/health", status_code=status.HTTP_200_OK)
def health_check():
    """
    Stateless health check endpoint for ALB target group.
    Has no external database dependency to ensure fast, reliable target checks.
    """
    return {
        "status": "healthy",
        "environment": APP_ENV
    }


@app.get("/db-check")
def db_check():
    """
    End-to-end database connectivity verification endpoint.
    Connects to Amazon RDS PostgreSQL using TLS (sslmode='require'),
    runs 'SELECT version();', and returns status without exposing sensitive credentials.
    """
    if not DB_HOST or not DB_PASSWORD:
        logger.error("Database connection failed: DB_HOST or DB_PASSWORD environment variable is missing")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={"status": "error", "message": "Database configuration incomplete"}
        )

    conn = None
    try:
        # Enforce TLS encryption (RDS PostgreSQL 15+ defaults force_ssl = 1)
        conn = psycopg2.connect(
            host=DB_HOST,
            port=int(DB_PORT),
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            sslmode="require",
            connect_timeout=5
        )
        with conn.cursor() as cur:
            cur.execute("SELECT version();")
            pg_version = cur.fetchone()[0]

        logger.info("Successfully connected to RDS PostgreSQL database over TLS")
        return {
            "status": "ok",
            "database": "connected",
            "ssl_active": True,
            "postgres_version": pg_version
        }
    except Exception as exc:
        # Sanitize logs to never leak credentials
        logger.error("Failed to connect to PostgreSQL database: %s", str(exc).split("password=")[0])
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={
                "status": "error",
                "message": "Database connection failed"
            }
        )
    finally:
        if conn is not None:
            conn.close()
