# Terraform Project Guide

This project demonstrates how to code and manage AWS infrastructure using Terraform.

## Table of Contents

- [Terraform Project Guide](#terraform-project-guide)
  - [Table of Contents](#table-of-contents)
  - [Project Overview](#project-overview)
  - [Required Tools](#required-tools)
  - [Project Structure](#project-structure)
  - [Initial Setup](#initial-setup)
  - [S3 Bucket Creation](#s3-bucket-creation)
  - [Backend Migration](#backend-migration)
  - [Infrastructure Creation](#infrastructure-creation)
  - [Resource Deletion](#resource-deletion)
  - [Troubleshooting](#troubleshooting)

## Project Overview

This project creates the following AWS resources:
- S3 bucket (for storing Terraform state files)
- VPC and subnets
- Internet Gateway
- Route tables
- EC2 instance
- Security groups

## Required Tools

- [Terraform](https://www.terraform.io/downloads.html) (v1.0.0 or higher)
- [AWS CLI](https://aws.amazon.com/cli/)
- AWS account and IAM user (with appropriate permissions)

## Project Structure

```
.
├── backend.tf       # Backend configuration
├── bucket.tf        # S3 bucket configuration
├── vpc.tf           # VPC and network configuration
├── ec2.tf           # EC2 instance configuration
├── variables.tf     # Variable definitions
└── terraform.tfvars # Variable values
```

## Initial Setup

1. **Clean up existing resources** (if needed)
   ```bash
   # Delete existing state files (if local)
   rm -f terraform.tfstate terraform.tfstate.backup

   # Delete existing .terraform directory
   rm -rf .terraform
   ```

2. **Backend configuration**
   - Modify `backend.tf` file to use local backend:
   ```hcl
   terraform {
     required_version = ">= 1.0.0"
     
     # Use local backend
     backend "local" {}

     # Required providers
     required_providers {
       aws = {
         source  = "hashicorp/aws"
         version = "~> 5.0"
       }
     }
   }
   ```

3. **Initialize Terraform**
   ```bash
   terraform init
   ```

## S3 Bucket Creation

1. **Create S3 bucket**
   ```bash
   terraform apply -target=aws_s3_bucket.terraform_state
   ```

2. **Verify S3 bucket settings**
   - Server-side encryption enabled
   - Public access blocked
   - Versioning enabled

## Backend Migration

1. **Change backend configuration**
   - Modify `backend.tf` file to use S3 backend:
   ```hcl
   terraform {
     required_version = ">= 1.0.0"
     
     # Use S3 backend
     backend "s3" {
       bucket         = "gunsu-private-bucket-8926937-state"
       key            = "terraform.tfstate"
       region         = "us-east-1"
       encrypt        = true
     }

     # Required providers
     required_providers {
       aws = {
         source  = "hashicorp/aws"
         version = "~> 5.0"
       }
     }
   }
   ```

2. **Migrate state file**
   ```bash
   terraform init -migrate-state
   ```

## Infrastructure Creation

1. **Create all resources**
   ```bash
   terraform apply
   ```

2. **Verify created resources**
   - Check in AWS Console that the following resources have been created:
     - S3 bucket (gunsu-private-bucket-8926937-state)
     - terraform.tfstate file in the S3 bucket <br>
     <img width="1465" alt="Image" src="https://github.com/user-attachments/assets/ea9b0e06-3ed6-4ea5-a877-7add101ff547" /> <br>
     - VPC (gunsu-vpc) <br>
     <img width="1523" alt="Image" src="https://github.com/user-attachments/assets/557fdeb3-9e40-4411-b73e-6cb60daa1067" /> <br>
     - Public subnet (terraform-project-public-subnet) <br>
     <img width="1510" alt="Image" src="https://github.com/user-attachments/assets/25b00db2-a5ce-4a65-99e6-b8191be21041" /> <br>
     - Internet Gateway (terraform-project-igw) <br>
     <img width="1509" alt="Image" src="https://github.com/user-attachments/assets/0cf5da02-39a7-4636-a030-f0c4f3378afe" />  <br>
     - Route table (terraform-project-public-rt) <br>
     <img width="1498" alt="Image" src="https://github.com/user-attachments/assets/d96f8dfc-79c0-4b4b-b7bf-2c4c7c562fce" /> <br>
     - EC2 instance (terraform-project-web-server) <br>
     <img width="1522" alt="Image" src="https://github.com/user-attachments/assets/e2a47d5f-4b7d-4ddb-a285-c40b82789872" /> <br>
     - Security group (terraform-project-ec2-sg) <br>
     <img width="1465" alt="Image" src="https://github.com/user-attachments/assets/34075a5a-6d0f-4d75-aabb-ffa843bfec29" />  <br>

## Resource Deletion

1. **Delete all resources**
   ```bash
   terraform destroy
   ```

2. **S3 bucket deletion issues**
   - S3 bucket must be empty before deletion.
   - If versioning is enabled, all versions of objects must be deleted.

## Troubleshooting

1. **IAM permission issues**
   - Problem: Cannot create resources due to insufficient IAM permissions.
   - Solution: Add necessary permissions in AWS IAM console.
   - Required permissions: `s3:CreateBucket`, `ec2:CreateVpc`, etc.