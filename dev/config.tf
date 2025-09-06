data "aws_caller_identity" "current" {}

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
  backend "s3" {
    bucket  = "devops-practice-lmv-dev"
    key     = "dp_001/terraform/tfstate/infra.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.10.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.0.2"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
      command     = "aws"
    }
  }
}