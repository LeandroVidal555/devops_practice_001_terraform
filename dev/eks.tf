module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.6.1"

  name               = local.eks_cluster.name
  kubernetes_version = local.eks_cluster.cluster_version

  # Private API endpoint only
  endpoint_private_access = local.eks_cluster.endpoint_private_access

  endpoint_public_access       = var.enable_public_api ? true : false
  endpoint_public_access_cidrs = var.enable_public_api && var.github_actions_egress_cidr != null ? [var.github_actions_egress_cidr] : [] # ignored when public access is false

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets # control plane ENIs + nodes in private subnets

  enable_irsa = true

  node_security_group_tags = {
    "karpenter.sh/discovery" = local.eks_cluster.name
  }

  # Core add-ons (latest)
  addons = {
    kube-proxy = {
      most_recent = true
    }

    vpc-cni = {
      most_recent    = true
      before_compute = true
    }
  }

  # Let the creator be cluster admin
  enable_cluster_creator_admin_permissions = true
}

resource "aws_eks_addon" "coredns" {
  depends_on = [module.eks] # warning: addon will have to wait for bootstrap

  cluster_name = module.eks.cluster_name
  addon_name   = "coredns"
}

resource "helm_release" "metrics_server" {
  depends_on = [
    aws_eks_addon.coredns
  ]

  name       = "metrics-server"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = var.met_srv_chart_version

  set = [
    {
      name  = "args[0]"
      value = "--kubelet-preferred-address-types=InternalIP\\,Hostname\\,ExternalIP"
    }
  ]
}