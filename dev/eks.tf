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

# IAM role that EC2 instances in the node group will assume
resource "aws_iam_role" "worker_nodes_role" {
  name = "${var.env}-${var.common_prefix}-worker-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach the three managed policies required for EKS nodes
resource "aws_iam_role_policy_attachment" "worker_nodes_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ])

  role       = aws_iam_role.worker_nodes_role.name
  policy_arn = each.key
}


# Separate managed node group(s)
module "mng_workers" {
  depends_on = [aws_eks_access_entry.worker_nodes]

  source  = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version = "21.6.1"

  name               = "workers"
  kubernetes_version = local.eks_cluster.cluster_version

  cluster_name         = module.eks.cluster_name
  cluster_service_cidr = module.eks.cluster_service_cidr
  subnet_ids           = module.vpc.private_subnets

  create_iam_role = false
  iam_role_arn    = aws_iam_role.worker_nodes_role.arn

  vpc_security_group_ids = [module.eks.node_security_group_id]

  capacity_type  = local.eks_cluster.capacity_type
  instance_types = local.eks_cluster.instance_types

  min_size     = local.eks_cluster.min_size
  desired_size = local.eks_cluster.desired_size
  max_size     = local.eks_cluster.max_size

  ami_type  = local.eks_cluster.ami_type
  disk_size = local.eks_cluster.disk_size

  labels = { workload = "general_workers" }

  metadata_options = {
    http_put_response_hop_limit = 2
  }

  timeouts = {
    create = "15m" # default is 60m
    update = "15m"
    delete = "15m"
  }
}

resource "aws_eks_addon" "coredns" {
  cluster_name = module.eks.cluster_name
  addon_name   = "coredns"
  depends_on   = [module.mng_workers] # ensure nodes exist first
}