variable "region" {
    description = "aws region"
    type = string
}

variable "bucket_count" {
    description = "number of buckets"
    type = number
}

variable "file_path" {
  description = "File path"
  type        = string
}

variable "bucket_prefix" {
    description = "Prefix for the bucket names"
    type        = string
}

variable "student_id" {
    description = "Student ID to include in the bucket name"
    type        = string
}

variable "aws_access_key" {
  description = "AWS Access Key"
  type        = string
}

variable "aws_secret_key" {
  description = "AWS Secret Key"
  type        = string
}

variable "aws_session_token" {
  description = "AWS Session Token (optional)"
  type        = string
}

# VPC and EC2 related variables
variable "project_name" {
  description = "Name of the project, used for resource naming"
  type        = string
  default     = "terraform-project"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Availability zone for the public subnet"
  type        = string
  default     = "us-east-1a"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
  default     = "ami-0c7217cdde317cfec" # Amazon Linux 2 AMI in us-east-1
}

variable "instance_type" {
  description = "Instance type for the EC2 instance"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the SSH key pair to use for the EC2 instance"
  type        = string
  default     = "terraform-key"
}