#### GENERAL ####
aws_region    = "us-east-1"
common_prefix = "dp-001"
env           = "dev"

#### VPC ####
vpc_cidr              = "10.0.0.0/16"
private_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24"]
public_subnet_cidrs   = ["10.0.100.0/24", "10.0.101.0/24"]
isolated_subnet_cidrs = ["10.0.200.0/24", "10.0.201.0/24"]