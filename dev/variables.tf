#### GENERAL ####
variable "aws_region" { type = string }
variable "common_prefix" { type = string }
variable "env" { type = string }

#### VPC ####
variable "vpc_cidr" { type = string }
variable "private_subnet_cidrs" { type = list(string) }
variable "public_subnet_cidrs" { type = list(string) }
variable "isolated_subnet_cidrs" { type = list(string) }

#### EKS ####
variable "cluster_version" { type = string }
variable "admin_sso_role_hash" { type = string }
variable "argocd_chart_version" { type = string }
variable "albcont_chart_version" { type = string }
variable "met_srv_chart_version" { type = string }
variable "enable_public_api" {
  type    = bool
  default = false
}
variable "github_actions_egress_cidr" { # introduced by github actions workflow as envvar
  type    = string
  default = null
}
variable "deploy_apps" {
  type    = bool
  default = false
}
variable "domain" { type = string }
variable "acm_cert_arn" { type = string }