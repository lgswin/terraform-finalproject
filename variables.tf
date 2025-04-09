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