variable "name" { type = string }
variable "ami_id" { type = string }
variable "instance_type" { type = string }
variable "subnet_id" { type = string }
variable "user_data_file" { type = file }
variable "policy_file" { type = file }
variable "vpc_id" { type = string }