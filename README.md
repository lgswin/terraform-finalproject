# Terraform AWS Infrastructure Setup

This project sets up a complete AWS infrastructure using Terraform, including VPC, EC2, S3, and DynamoDB resources.

## Infrastructure Diagram

```
    AWS Cloud (us-east-1)
    +------------------+
    |                  |
    |  +------------+  |
    |  |            |  |
    |  |   VPC      |  |
    |  | 10.0.0.0/16|  |
    |  |            |  |
    |  +------------+  |
    |        |         |
    |        |         |
    |  +------------+  |
    |  |            |  |
    |  |  Public    |  |
    |  |  Subnet    |  |
    |  |10.0.1.0/24 |  |
    |  |            |  |
    |  +------------+  |
    |        |         |
    |        |         |
    |  +------------+  |
    |  |            |  |
    |  |   EC2      |  |
    |  | Instance   |  |
    |  | (t2.micro) |  |
    |  |            |  |
    |  +------------+  |
    |        |         |
    |        |         |
    |  +------------+  |
    |  |            |  |
    |  | Internet   |  |
    |  | Gateway    |  |
    |  |            |  |
    |  +------------+  |
    |                  |
    +------------------+
            |
            |
    +------------------+
    |                  |
    |  +------------+  |
    |  |            |  |
    |  |    S3      |  |
    |  |   Bucket   |  |
    |  |            |  |
    |  +------------+  |
    |                  |
    |  +------------+  |
    |  |            |  |
    |  | DynamoDB   |  |
    |  |   Table    |  |
    |  |            |  |
    |  +------------+  |
    |                  |
    +------------------+
```

### Infrastructure Components

1. **VPC (Virtual Private Cloud)**
   - CIDR: 10.0.0.0/16
   - DNS hostnames and support enabled
   - Container for all network resources

2. **Public Subnet**
   - CIDR: 10.0.1.0/24
   - Availability Zone: us-east-1a
   - Automatic public IP assignment enabled

3. **EC2 Instance**
   - Instance Type: t2.micro
   - Amazon Linux 2 AMI
   - Located in public subnet
   - Connected to security group (SSH, HTTP, HTTPS)

4. **Internet Gateway**
   - Connected to VPC
   - Enables internet communication
   - Associated with public subnet's route table

5. **S3 Bucket**
   - Name: gunsu-private-bucket-8926937-state
   - Versioning enabled
   - Server-side encryption (AES256)
   - Public access blocked

6. **DynamoDB Table**
   - Name: terraform-state-lock
   - On-demand billing
   - LockID as primary key
   - State lock management

### Security Configuration
- Environment tags applied to all resources
- S3 bucket public access blocked
- EC2 security group port restrictions
- State file encryption

This infrastructure is managed by Terraform, with state files stored in S3 and lock management handled by DynamoDB.

## 1. Backend Configuration (backend.tf)

The backend configuration defines how Terraform state is stored and managed.

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

Key components:
- `required_version`: Ensures Terraform version 1.0.0 or higher
- `backend "s3"`: Configures S3 as the state storage backend
  - `bucket`: S3 bucket for state file storage
  - `key`: State file path and name
  - `region`: AWS region for the bucket
  - `encrypt`: Enables state file encryption
  - `dynamodb_table`: DynamoDB table for state locking
- `required_providers`: Specifies AWS provider version 5.0 or higher

## 2. S3 Bucket Configuration (bucket.tf)

S3 bucket configuration for secure state storage.

### Bucket Creation
```hcl
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.bucket_name
  tags = {
    Name        = var.bucket_name
    Environment = var.environment
  }
}
```
This creates an S3 bucket with:
- Custom bucket name from variables
- Resource identification tags
- Environment-specific tagging

### Versioning Configuration
```hcl
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}
```
Enables versioning to:
- Track all state file changes
- Prevent accidental deletion
- Maintain state history

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
Configures encryption with:
- AES256 algorithm
- AWS KMS key management
- Automatic encryption of all objects

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
Secures the bucket by:
- Blocking all public access
- Preventing public bucket policies
- Ignoring public ACLs
- Restricting public bucket access

## 3. DynamoDB Table Configuration (dynamodb.tf)

DynamoDB table for state locking.

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
Creates a DynamoDB table with:
- On-demand billing
- LockID as primary key
- String type attribute
- Resource identification tags

## 4. EC2 Configuration (ec2.tf)

EC2 instance and security group configuration.

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
Configures security group with:
- SSH access (port 22)
- HTTP access (port 80)
- HTTPS access (port 443)
- All outbound traffic allowed
- Resource identification tags

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
Creates EC2 instance with:
- Specified AMI and instance type
- Public subnet placement
- Security group attachment
- Public IP assignment
- Resource identification tags

## 5. VPC Configuration (vpc.tf)

VPC and networking configuration.

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
Creates VPC with:
- Custom CIDR block
- DNS support enabled
- DNS hostnames enabled
- Resource identification tags

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
Creates public subnet with:
- VPC association
- Custom CIDR block
- Availability zone placement
- Automatic public IP assignment
- Resource identification tags

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
Creates internet gateway with:
- VPC attachment
- Resource identification tags

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
Creates route table with:
- VPC association
- Internet route (0.0.0.0/0)
- Resource identification tags

### Route Table Association
```hcl
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
```
Associates public subnet with:
- Route table
- Internet gateway routing

## 6. Variables Definition (variables.tf)

Variable declarations and types.

### AWS Region
```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
```
Defines AWS region with:
- String type
- Default value: us-east-1

### Bucket Name
```hcl
variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}
```
Defines S3 bucket name as:
- Required string variable
- No default value

### DynamoDB Table Name
```hcl
variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  type        = string
}
```
Defines DynamoDB table name as:
- Required string variable
- No default value

### Environment
```hcl
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}
```
Defines environment with:
- String type
- Default value: dev

### Instance Type
```hcl
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}
```
Defines EC2 instance type with:
- String type
- Default value: t2.micro (free tier)

### AMI ID
```hcl
variable "ami_id" {
  description = "AMI ID for EC2 instance"
  type        = string
}
```
Defines AMI ID as:
- Required string variable
- No default value

### VPC CIDR
```hcl
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}
```
Defines VPC CIDR with:
- String type
- Default value: 10.0.0.0/16

### Public Subnet CIDR
```hcl
variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}
```
Defines public subnet CIDR with:
- String type
- Default value: 10.0.1.0/24

## 7. Variable Values (terraform.tfvars)

Actual values for the defined variables.

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
Sets values for:
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

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Apply the configuration:
   ```bash
   terraform apply
   ```
   This creates:
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
   terraform init -migrate-state
   ```
   - When prompted, type 'yes' to confirm migration

### Phase 3: Regular Operations
After migration, use these commands:
```bash
terraform init
terraform plan
terraform apply
```

## AWS Console Verification
After deployment, verify in AWS Console:
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