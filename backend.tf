terraform {
  required_version = ">= 1.0.0"
  
  backend "local" {}

  # Required providers
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
} 