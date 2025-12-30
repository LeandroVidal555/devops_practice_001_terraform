data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.5.0"

  name = "${var.aws_region}-${var.common_prefix}-vpc"
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets  = var.public_subnet_cidrs
  private_subnets = var.private_subnet_cidrs
  intra_subnets   = var.isolated_subnet_cidrs

  public_subnet_tags = {
    "kubernetes.io/role/elb"                          = "1"      # ALBC
    "kubernetes.io/cluster/${local.eks_cluster.name}" = "shared" # ALBC
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"                 = "1"                    # ALBC
    "kubernetes.io/cluster/${local.eks_cluster.name}" = "shared"               # ALBC
    "karpenter.sh/discovery"                          = local.eks_cluster.name # Karpenter
  }

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true
}