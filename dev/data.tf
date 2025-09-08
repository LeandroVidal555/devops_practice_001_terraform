data "aws_nat_gateway" "this" {
  filter {
    name = "vpc-id"
    values = [module.vpc.vpc_id]
  }
  state = "available"
}