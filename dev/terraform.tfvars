#### GENERAL ####
aws_region    = "us-east-1"
common_prefix = "dp-001"
env           = "dev"

#### VPC ####
vpc_cidr              = "10.0.0.0/16"
private_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24"]
public_subnet_cidrs   = ["10.0.100.0/24", "10.0.101.0/24"]
isolated_subnet_cidrs = ["10.0.200.0/24", "10.0.201.0/24"]

#### EKS ####
cluster_version       = "1.34"
admin_sso_role_hash   = "e59d6194b0ea5059"
argocd_chart_version  = "8.3.4"
albcont_chart_version = "1.14.1"
met_srv_chart_version = "3.13.0"
acm_cert_arn          = "arn:aws:acm:us-east-1:381443105190:certificate/8c7b8504-192e-41e4-8e4d-42e6f828e1c5"
domain                = "lmv-dev.top"

#### MONITORING ####
vm_chart_version      = "0.25.2"
vmagent_chart_version = "0.26.2"
grafana_chart_version = "10.1.4"
kube_state_metrics_chart_version = "6.4.0"
node_exporter_chart_version = "4.49.1"