terraform {
  required_version = ">= 1.0.0"
  
  # S3 백엔드 사용
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

  #  terraform {
  #    backend "local" {}
  #  }