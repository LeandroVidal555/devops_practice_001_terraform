module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.1.5"

  name = "${var.aws_region}-${var.common_prefix}-cluster"

  # Private API endpoint only
  endpoint_public_access  = local.eks_cluster.endpoint_public_access
  endpoint_private_access = local.eks_cluster.endpoint_private_access

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets # control plane ENIs + nodes in private subnets

  enable_irsa = true

  # Core add-ons (latest)
  addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni    = {}
  }

  # Let the creator be cluster admin
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    workers = {
      kubernetes_version = local.eks_cluster.k8s_version
      capacity_type      = local.eks_cluster.capacity_type
      instance_types     = local.eks_cluster.instance_types

      min_size     = local.eks_cluster.min_size
      desired_size = local.eks_cluster.desired_size
      max_size     = local.eks_cluster.max_size

      ami_type  = local.eks_cluster.ami_type
      disk_size = local.eks_cluster.disk_size

      subnet_ids = module.vpc.private_subnets
      labels     = { workload = "general_workers" }
    }
  }
}
