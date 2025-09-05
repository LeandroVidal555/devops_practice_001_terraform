data "aws_caller_identity" "current" {}

terraform {
  backend "s3" {
    bucket  = "devops-practice-lmv-dev"
    key     = "dp_001/terraform/tfstate/infra.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

locals {
  common_tags = {
    Environment = var.env
    ManagedBy   = "Terraform"
    Project     = "DevOps Practice 001"
    Owner       = "Leandro Vidal"
    Contact     = "lmv.vidal@gmail.com"
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.10.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}