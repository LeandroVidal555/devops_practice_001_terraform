variable "name" { type = string }
variable "instance_type" { type = string }
variable "subnet_id" { type = string }
variable "user_data_file" { type = string }
variable "user_data_replace_on_change" { type = bool }
variable "policy_file" { type = string }
variable "vpc_id" { type = string }