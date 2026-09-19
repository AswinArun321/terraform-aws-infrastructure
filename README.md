# AWS Infrastructure Provisioning with Terraform

Infrastructure as Code project for provisioning a complete AWS application environment using **Terraform**.

The project automates the creation of a production-style AWS infrastructure consisting of networking, compute, load balancing, security, and database resources.

## 🚀 Project Overview

This project demonstrates how Terraform can be used to provision and manage AWS infrastructure instead of configuring resources manually through the AWS Management Console.

The infrastructure includes:

- Amazon VPC
- Public and private subnets
- Security groups
- ECS Fargate cluster
- Application Load Balancer
- Amazon RDS PostgreSQL
- Terraform modules
- Remote Terraform state

The infrastructure can be reused for different environments such as **development and staging** by changing configuration variables.

## 🏗️ Architecture

```text
                    Internet
                       |
                       v
              +------------------+
              |       ALB        |
              | Application      |
              | Load Balancer    |
              +--------+---------+
                       |
                       v
              +------------------+
              |   ECS Fargate    |
              |     Cluster      |
              +--------+---------+
                       |
                       v
              +------------------+
              |  RDS PostgreSQL  |
              +------------------+

              AWS VPC
        +-----------------------+
        |                       |
        | Public Subnets        |
        | Private Subnets       |
        | Security Groups       |
        |                       |
        +-----------------------+
```

## 🛠️ Technologies Used

| Technology | Purpose |
|---|---|
| Terraform | Infrastructure as Code |
| AWS VPC | Network infrastructure |
| AWS ECS | Container orchestration |
| AWS Fargate | Serverless container execution |
| Application Load Balancer | Application traffic distribution |
| Amazon RDS | PostgreSQL database |
| AWS Security Groups | Network access control |
| Terraform Modules | Reusable infrastructure components |
| Terraform Remote State | Centralized state management |

## 📁 Project Structure

```text
terraform-aws-infrastructure/
│
├── main.tf
├── variables.tf
├── outputs.tf
├── providers.tf
├── terraform.tfvars
├── backend.tf
├── README.md
│
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── security-groups/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── ecs/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── alb/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── rds/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
└── environments/
    ├── dev/
    └── staging/
```

> Adjust the structure above to match the actual files in your repository.

## ⚙️ Infrastructure Components

### 1. VPC

Terraform creates the AWS networking environment required by the application.

The VPC contains:

- Public subnets
- Private subnets
- Networking configuration
- Security boundaries

### 2. Security Groups

Security groups control network access between the different AWS resources.

For example:

```text
Internet
   |
   v
  ALB
   |
   v
ECS Fargate
   |
   v
RDS PostgreSQL
```

Traffic is controlled between these layers using appropriate security-group rules.

### 3. ECS Fargate

The project provisions an **Amazon ECS Fargate cluster** for running containerized workloads.

Fargate removes the need to manage EC2 servers for the ECS workloads.

### 4. Application Load Balancer

The Application Load Balancer provides an entry point for application traffic and distributes requests to the ECS service.

### 5. RDS PostgreSQL

An Amazon RDS PostgreSQL instance provides the persistent relational database layer for the application.

### 6. Terraform Modules

The infrastructure is organized into reusable Terraform modules.

This makes the configuration easier to:

- Maintain
- Reuse
- Modify
- Scale
- Deploy across environments

## 🌍 Environment Management

The Terraform configuration is designed so that the same infrastructure configuration can be used for different environments.

For example:

```text
             Terraform Configuration
                       |
              +--------+--------+
              |                 |
              v                 v
          Development        Staging
```

Environment-specific values can be supplied through variables rather than duplicating the entire infrastructure configuration.

## 🔐 Remote State

Terraform remote state is used to maintain infrastructure state centrally.

This allows infrastructure changes to be tracked consistently and makes the Terraform configuration more suitable for collaborative environments.

> Do not commit Terraform state files or sensitive credentials to GitHub.

## 📋 Prerequisites

Before running the project, install:

- Terraform
- AWS CLI
- An AWS account
- Git

Verify Terraform:

```bash
terraform version
```

Verify AWS CLI:

```bash
aws --version
```

Configure your AWS credentials:

```bash
aws configure
```

## 🚀 Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/AswinArun321/<repository-name>.git
```

```bash
cd <repository-name>
```

### 2. Initialize Terraform

```bash
terraform init
```

This initializes the Terraform working directory and downloads the required providers and modules.

### 3. Validate the configuration

```bash
terraform validate
```

### 4. Format Terraform files

```bash
terraform fmt -recursive
```

### 5. Review the execution plan

```bash
terraform plan
```

Review the resources Terraform is going to create before applying the configuration.

### 6. Provision the infrastructure

```bash
terraform apply
```

Confirm the operation when Terraform asks for approval.

## 🧹 Destroy Infrastructure

When the infrastructure is no longer required:

```bash
terraform destroy
```

Review the resources carefully before confirming the destruction.

## 📊 Project Outcome

The project focuses on replacing manual AWS infrastructure configuration with automated Infrastructure as Code.

According to the project implementation:

- Environment setup was reduced from a **multi-hour manual console process to a single `terraform apply` taking under 10 minutes**.
- Modular Terraform configuration allows the same infrastructure to be used for **development and staging** with configuration changes rather than duplicated infrastructure code.
- AWS networking, compute, load balancing, and database infrastructure are provisioned through Terraform.

## 🎯 Key Learning Outcomes

Through this project, the following concepts are demonstrated:

- Infrastructure as Code
- Terraform fundamentals
- Terraform modules
- AWS VPC architecture
- AWS ECS and Fargate
- Application Load Balancer
- Amazon RDS PostgreSQL
- AWS security groups
- Terraform variables and outputs
- Remote Terraform state
- Multi-environment infrastructure
- Automated cloud infrastructure provisioning

## 🔮 Future Improvements

Possible future enhancements include:

- Add Terraform CI/CD using GitHub Actions
- Add automated `terraform plan` checks for pull requests
- Add Terraform security scanning
- Add infrastructure monitoring
- Add AWS CloudWatch integration
- Add autoscaling configuration
- Add separate production environment
- Improve secrets management using AWS Secrets Manager
- Add infrastructure diagrams and deployment documentation

## 👨‍💻 Author

**Aswin Arunkumar A**

MSc Computer Science (Data Analytics)  
Rajagiri College of Social Sciences

- GitHub: [AswinArun321](https://github.com/AswinArun321)
- LinkedIn: Add your LinkedIn profile here

## 📄 License

This project is intended for educational and portfolio purposes.