#### GENERAL ####
variable "aws_region" { type = string }
variable "common_prefix" { type = string }
variable "env" { type = string }

#### VPC ####
variable "vpc_cidr" { type = string }
variable "private_subnet_cidrs" { type = list(string) }
variable "public_subnet_cidrs" { type = list(string) }
variable "isolated_subnet_cidrs" { type = list(string) }