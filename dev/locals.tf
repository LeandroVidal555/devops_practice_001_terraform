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
    capacity_type           = "ON_DEMAND"
    instance_types          = ["t3a.small", "t3.small"] # 8 enis # ["t3a.small", "t3.small"] # 17 enis
    min_size                = 3
    desired_size            = 3
    max_size                = 3
    ami_type                = "AL2023_x86_64_STANDARD"
    disk_size               = 50
    admin_roles = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_AdministratorAccess_${var.admin_sso_role_hash}",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.env}-${var.common_prefix}-bastion-role"
    ],
    bootstrap_policy_arns = toset([
      "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
      "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
      "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly",
      "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    ])
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
      vm_persistence          = false
      vm_storage_size_gi      = 50
      vm_retention_months     = 1
      vmagent_persistence     = false
      vmagent_buffer_size_gi  = 10
      vmagent_scrape_interval = "30s"
    }
    grafana = {
      grafana_admin_password  = "admin"
      grafana_persistence     = false
      grafana_storage_size_gi = 10
    }
    loki = {
      loki_persistence     = false
      loki_storage_size_gi = 10
    }
  }
  app_infra = {
    site_url          = "${var.common_prefix}.${var.env}.${var.tl_domain}"
    api_alb_origin_id = "app-alb"
  }
  updater_lambda = {
    lambda_name    = "${var.env}-${var.common_prefix}-updater-lambda"
    alb_app_name   = "${var.env}-${var.common_prefix}-app-alb"
    alb_admin_name = "${var.env}-${var.common_prefix}-admin-alb"
    alb_domains    = "argo.${var.env}.${var.tl_domain},grafana.${var.env}.${var.tl_domain}"
    cfront_zone_id = "Z2FDTNDATAQYW2"
    python_runtime = "python3.12"
    bucket_name    = "${var.env}-${var.common_prefix}-cloudtrail"
  }
  karpenter = {
    service_account = "karpenter"
  }
}