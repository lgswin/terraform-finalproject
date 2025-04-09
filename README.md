# Terraform AWS Infrastructure Setup

This project sets up a complete AWS infrastructure using Terraform, including VPC, EC2, S3, and DynamoDB resources.

## 1. Backend Configuration (backend.tf)

### S3 Backend Setup
```hcl
terraform {
  required_version = ">= 1.0.0"
  
  backend "s3" {
    bucket         = "gunsu-private-bucket-8926937-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

- **required_version**: Requires Terraform version 1.0.0 or higher
- **backend "s3"**: 
  - `bucket`: S3 bucket name for storing state file
  - `key`: Path and name of the state file
  - `region`: AWS region
  - `encrypt`: Enable state file encryption
  - `dynamodb_table`: DynamoDB table for state locking
- **required_providers**: Specifies AWS provider version 5.0 or higher

## 2. S3 Bucket Configuration (bucket.tf)

### S3 Bucket Creation
```hcl
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.bucket_name
  tags = {
    Name        = var.bucket_name
    Environment = var.environment
  }
}
```
- Creates S3 bucket with specified name
- Adds tags for resource identification (name, environment)

### Versioning Configuration
```hcl
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}
```
- Enables versioning on the bucket
- Tracks all changes to the state file
- Protects against accidental deletion or modification

### Server-Side Encryption
```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```
- Applies server-side encryption using AES256 algorithm
- Enhances security of stored data
- Manages keys through AWS KMS

### Public Access Block
```hcl
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```
- Blocks all public access
- Blocks public access through bucket policies
- Ignores public access through ACLs
- Restricts public buckets

## 3. DynamoDB Table Configuration (dynamodb.tf)

### State Lock Table
```hcl
resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = var.dynamodb_table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = var.dynamodb_table_name
    Environment = var.environment
  }
}
```
- Creates DynamoDB table for state locking
- Uses on-demand billing (pay per usage)
- Sets LockID as the primary key
- Adds tags for resource identification

## 4. EC2 Configuration (ec2.tf)

### Security Group
```hcl
resource "aws_security_group" "ec2_sg" {
  name        = "gunsu-ec2-sg"
  description = "Security group for EC2 instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "gunsu-ec2-sg"
    Environment = var.environment
  }
}
```
- Creates security group for EC2 instance
- Allows inbound traffic on SSH(22), HTTP(80), and HTTPS(443) ports
- Allows all outbound traffic
- Adds tags for resource identification

### EC2 Instance
```hcl
resource "aws_instance" "ec2" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true

  tags = {
    Name        = "gunsu-ec2"
    Environment = var.environment
  }
}
```
- Creates EC2 instance with specified AMI and instance type
- Places in public subnet
- Connects security group
- Assigns public IP address
- Adds tags for resource identification

## 5. VPC Configuration (vpc.tf)

### VPC Creation
```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "gunsu-vpc"
    Environment = var.environment
  }
}
```
- Creates VPC with specified CIDR block
- Enables DNS hostnames and support
- Adds tags for resource identification

### Public Subnet
```hcl
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidr
  availability_zone = "${var.aws_region}a"

  map_public_ip_on_launch = true

  tags = {
    Name        = "gunsu-public-subnet"
    Environment = var.environment
  }
}
```
- Creates public subnet within VPC
- Places in specified availability zone
- Enables automatic public IP assignment
- Adds tags for resource identification

### Internet Gateway
```hcl
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "gunsu-igw"
    Environment = var.environment
  }
}
```
- Connects internet gateway to VPC
- Enables communication with the internet
- Adds tags for resource identification

### Route Table
```hcl
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "gunsu-public-rt"
    Environment = var.environment
  }
}
```
- Creates public routing table
- Sets up routing to internet (0.0.0.0/0 -> IGW)
- Adds tags for resource identification

### Route Table Association
```hcl
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
```
- Associates public subnet with routing table
- Routes subnet traffic to internet gateway

## 6. Variables Definition (variables.tf)

### AWS Region
```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
```
- Specifies AWS region
- Default value: us-east-1

### Bucket Name
```hcl
variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}
```
- Specifies S3 bucket name
- Required input variable

### DynamoDB Table Name
```hcl
variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  type        = string
}
```
- Specifies DynamoDB table name
- Required input variable

### Environment
```hcl
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}
```
- Specifies environment name
- Default value: dev

### Instance Type
```hcl
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}
```
- Specifies EC2 instance type
- Default value: t2.micro (free tier)

### AMI ID
```hcl
variable "ami_id" {
  description = "AMI ID for EC2 instance"
  type        = string
}
```
- Specifies AMI ID for EC2 instance
- Required input variable

### VPC CIDR
```hcl
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}
```
- Specifies CIDR block for VPC
- Default value: 10.0.0.0/16

### Public Subnet CIDR
```hcl
variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}
```
- Specifies CIDR block for public subnet
- Default value: 10.0.1.0/24

## 7. Variable Values (terraform.tfvars)

### Resource Configuration
```hcl
aws_region           = "us-east-1"
bucket_name          = "gunsu-private-bucket-8926937-state"
dynamodb_table_name  = "terraform-state-lock"
environment          = "dev"
instance_type        = "t2.micro"
ami_id               = "ami-0c7217cdde317cfec"  # Amazon Linux 2 AMI
vpc_cidr            = "10.0.0.0/16"
public_subnet_cidr  = "10.0.1.0/24"
```
- AWS Region: us-east-1
- S3 Bucket Name: gunsu-private-bucket-8926937-state
- DynamoDB Table Name: terraform-state-lock
- Environment: Development
- Instance Type: t2.micro (free tier)
- AMI ID: Amazon Linux 2 AMI
- VPC CIDR: 10.0.0.0/16
- Public Subnet CIDR: 10.0.1.0/24

## Execution Sequence

### Phase 1: Initial Setup with Local Backend
1. Ensure backend.tf is configured to use local backend:
   ```hcl
   terraform {
     backend "local" {}
   }
   ```

2. Initialize Terraform with local backend:
   ```bash
   terraform init -var-file=vars.tfvars
   ```

3. Apply the configuration to create initial resources:
   ```bash
   terraform apply -var-file=vars.tfvars
   ```
   This will create:
   - S3 bucket for state storage
   - DynamoDB table for state locking
   - VPC and networking components
   - EC2 instance

### Phase 2: Migrate to S3 Backend
1. Update backend.tf to use S3 backend:
   ```hcl
   terraform {
     backend "s3" {
       bucket         = "gunsu-private-bucket-8926937-state"
       key            = "terraform.tfstate"
       region         = "us-east-1"
       encrypt        = true
       dynamodb_table = "terraform-state-lock"
     }
   }
   ```

2. Migrate state to S3:
   ```bash
   terraform init -migrate-state -var-file=vars.tfvars
   ```
   - When prompted, type 'yes' to confirm migration

### Phase 3: Regular Operations
After migration, use these commands for regular operations:
```bash
terraform init -var-file=vars.tfvars
terraform plan -var-file=vars.tfvars
terraform apply -var-file=vars.tfvars
```

## AWS Console Verification
After deployment, verify the infrastructure in AWS Console:
1. **S3**: Check `gunsu-private-bucket-8926937-state` bucket
2. **DynamoDB**: Verify `terraform-state-lock` table
3. **VPC**: Inspect `gunsu-vpc` and its components
4. **EC2**: Check `gunsu-ec2` instance
5. **IAM**: Verify necessary permissions

## Important Notes
- The `terraform.tfvars` file is gitignored for security
- Make sure to update the AMI ID in terraform.tfvars with a valid Amazon Linux 2 AMI
- The infrastructure is set up in the us-east-1 region by default
- EC2 instance type is set to t2.micro for free tier compatibility 