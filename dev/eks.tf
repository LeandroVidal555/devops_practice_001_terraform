module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.1.5"

  name               = "${var.env}-${var.common_prefix}-cluster"
  kubernetes_version = local.eks_cluster.cluster_version

  # Private API endpoint only
  endpoint_private_access = local.eks_cluster.endpoint_private_access

  endpoint_public_access       = var.enable_public_api ? true : false
  endpoint_public_access_cidrs = var.enable_public_api && var.github_actions_egress_cidr != null ? [var.github_actions_egress_cidr] : [] # ignored when public access is false

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets # control plane ENIs + nodes in private subnets

  enable_irsa = true

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

# Separate managed node group(s)
module "mng_workers" {
  source  = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version = "21.1.5"

  name               = "workers"
  kubernetes_version = local.eks_cluster.cluster_version

  cluster_name         = module.eks.cluster_name
  cluster_service_cidr = module.eks.cluster_service_cidr
  subnet_ids           = module.vpc.private_subnets

  cluster_primary_security_group_id = module.eks.cluster_primary_security_group_id
  vpc_security_group_ids            = [module.eks.node_security_group_id]

  capacity_type  = local.eks_cluster.capacity_type
  instance_types = local.eks_cluster.instance_types

  min_size     = local.eks_cluster.min_size
  desired_size = local.eks_cluster.desired_size
  max_size     = local.eks_cluster.max_size

  ami_type  = local.eks_cluster.ami_type
  disk_size = local.eks_cluster.disk_size

  labels = { workload = "general_workers" }

  timeouts = {
    create = "25m" # default is 60m
    update = "15m"
    delete = "15m"
  }
}

resource "aws_eks_addon" "coredns" {
  cluster_name = module.eks.cluster_name
  addon_name   = "coredns"
  depends_on   = [module.mng_workers] # ensure nodes exist first
}


resource "aws_eks_access_entry" "admin_roles" {
  for_each = toset(local.eks_cluster.admin_roles)

  cluster_name  = module.eks.cluster_name
  principal_arn = each.key
}

resource "aws_eks_access_policy_association" "admin_roles_policies" {
  for_each = aws_eks_access_entry.admin_roles

  cluster_name  = module.eks.cluster_name
  principal_arn = each.value.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}


resource "aws_security_group_rule" "bastion_access" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  description              = "Bastion to EKS API"
  security_group_id        = module.eks.cluster_security_group_id
  source_security_group_id = module.ec2_bastion.security_group_id
}

resource "aws_security_group_rule" "github_access" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  description       = "Github Actions to EKS API"
  security_group_id = module.eks.cluster_security_group_id
  cidr_blocks       = [var.github_actions_egress_cidr]

  count = var.enable_public_api ? 1 : 0
}
