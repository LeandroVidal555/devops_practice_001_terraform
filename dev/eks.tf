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


# IAM role that EC2 instances in the node group will assume
resource "aws_iam_role" "bootstrap_nodes_role" {
  name = "${var.env}-${var.common_prefix}-bootstrap-node-role"

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

# Attach the managed policies required for EKS nodes
resource "aws_iam_role_policy_attachment" "bootstrap_nodes_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ])

  role       = aws_iam_role.bootstrap_nodes_role.name
  policy_arn = each.key
}


# System Bootstrap managed node group
# This is needed because Karpenter is the service that provisions the worker nodes, 
#   so there has to be a first set of nodes that lets Karpenter and other Kubernetes system services run.
# After this Terraform config is deployed, GA applies Karpenter's manifests before apps/monitoring,
#   so the actual worker nodes start being created to provide capacity.
# In the end, the bootstrap nodes are cordoned, drained and deleted.
module "mng_bootstrap" {
  depends_on = [aws_eks_access_entry.bootstrap_nodes]

  source  = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version = "21.6.1"

  name               = "bootstrap"
  kubernetes_version = local.eks_cluster.cluster_version

  cluster_name         = module.eks.cluster_name
  cluster_service_cidr = module.eks.cluster_service_cidr
  subnet_ids           = module.vpc.private_subnets

  create_iam_role = false
  iam_role_arn    = aws_iam_role.bootstrap_nodes_role.arn

  vpc_security_group_ids = [module.eks.node_security_group_id]

  capacity_type  = local.eks_cluster.capacity_type
  instance_types = local.eks_cluster.instance_types

  min_size     = local.eks_cluster.min_size
  desired_size = local.eks_cluster.desired_size
  max_size     = local.eks_cluster.max_size

  ami_type  = local.eks_cluster.ami_type
  disk_size = local.eks_cluster.disk_size

  metadata_options = {
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  labels = {
    node-purpose = "bootstrap"
    karpenter    = "false"
  }

  update_config = {
    max_unavailable = 1
  }

  timeouts = {
    create = "15m" # default is 60m
    update = "15m"
    delete = "15m"
  }
}

resource "aws_eks_addon" "coredns" {
  depends_on = [module.mng_bootstrap] # ensure nodes exist first

  cluster_name = module.eks.cluster_name
  addon_name   = "coredns"
}

resource "helm_release" "metrics_server" {
  depends_on = [
    module.mng_bootstrap,
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