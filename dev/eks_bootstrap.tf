# IAM role that EC2 instances in the node group will assume
resource "aws_iam_role" "bootstrap_nodes_role" {
  count = var.deploy_apps ? 0 : 1 # this var is true after the apps were deployed, so bootstap is no longer needed
  name  = "${var.env}-${var.common_prefix}-bootstrap-node-role"

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
  for_each = var.deploy_apps ? toset([]) : local.eks_cluster.bootstrap_policy_arns

  role       = aws_iam_role.bootstrap_nodes_role[0].name
  policy_arn = each.key
}


# System Bootstrap managed node group
# This is needed because Karpenter is the service that provisions the worker nodes, 
#   so there has to be a first set of nodes that lets Karpenter and other Kubernetes system services run.
# After this Terraform config is deployed, GA applies Karpenter's manifests before apps/monitoring,
#   so the actual worker nodes start being created to provide capacity.
# In the end, the bootstrap nodes are cordoned, drained and deleted.
module "mng_bootstrap" {
  count      = var.deploy_apps ? 0 : 1
  depends_on = [aws_eks_access_entry.bootstrap_nodes]

  source  = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version = "21.6.1"

  name               = "bootstrap"
  kubernetes_version = local.eks_cluster.cluster_version

  cluster_name         = module.eks.cluster_name
  cluster_service_cidr = module.eks.cluster_service_cidr
  subnet_ids           = module.vpc.private_subnets

  create_iam_role = false
  iam_role_arn    = aws_iam_role.bootstrap_nodes_role[0].arn

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

resource "aws_eks_access_entry" "bootstrap_nodes" {
  count = var.deploy_apps ? 0 : 1

  cluster_name  = module.eks.cluster_name
  principal_arn = aws_iam_role.bootstrap_nodes_role[0].arn
  type          = "EC2_LINUX"
}