variable "aws_region" { type = string }
variable "karpenter_chart_version" { type = string }

# EKS
variable "cluster_name" { type = string }
variable "oidc_provider_arn" { type = string }