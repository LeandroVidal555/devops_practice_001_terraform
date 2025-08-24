locals {
  common_tags = {
    Environment = var.env
    ManagedBy   = "Terraform"
    Project     = "DevOps Practice 001"
    Owner       = "Leandro Vidal"
    Contact     = "lmv.vidal@gmail.com"
  }
}