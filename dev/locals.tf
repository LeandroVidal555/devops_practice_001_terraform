locals {
  ecr_repos = {
    "app" = {
      force_delete         = true
      image_tag_mutability = "MUTABLE"
      scan_on_push         = false
    }
  }
  eks_cluster = {
    name                    = "${var.env}-${var.common_prefix}-cluster"
    endpoint_private_access = true
    cluster_version         = var.cluster_version
    capacity_type           = "SPOT"
    instance_types          = ["t3a.medium", "t3.medium"]
    desired_size            = 2
    min_size                = 0
    max_size                = 3
    ami_type                = "AL2023_x86_64_STANDARD"
    disk_size               = 20
    admin_roles = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_AdministratorAccess_${var.admin_sso_role_hash}",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.env}-${var.common_prefix}-bastion-role"
    ]
  }
  argocd = {
    repo_org  = "LeandroVidal555"
    repo_name = "devops_practice_001_kubernetes"
    apps_path = "${var.env}/apps"
  }
  bastion = {
    instance_type               = "t2.micro"               # FREE TIER # or "t4g.micro"
    architecture                = "x86_64"                 # or "arm64"
    ami_regex                   = "al2023-ami-2023*x86_64" # or "al2023-ami-2023*arm64"
    subnet_id                   = module.vpc.private_subnets[0]
    user_data_file              = file("${path.module}/resources/user_data_bastion.sh")
    user_data_replace_on_change = true
    policy_file                 = file("${path.module}/resources/ec2_bastion_role.json")
  }
  monitoring = {
    monitoring_namespace = "monitoring"
    values_path          = "${path.module}/resources/monitoring/"
    vm = {
      vm_storage_size_gi      = 50
      vm_retention_months     = 1
      vmagent_buffer_size_gi  = 10
      vmagent_scrape_interval = "30s"
    }
    grafana = {
      grafana_admin_password  = "admin"
      grafana_persistence     = true
      grafana_storage_size_gi = 10
    }
    loki = {
      loki_persistence     = true
      loki_storage_size_gi = 10
    }
  }
}