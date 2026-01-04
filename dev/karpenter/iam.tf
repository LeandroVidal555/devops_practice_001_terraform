# This is for instances launched by karpenter, i.e., the actual workers
resource "aws_iam_role" "karpenter_node" {
  name = "${var.cluster_name}-karpenter-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_node_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ])

  role       = aws_iam_role.karpenter_node.name
  policy_arn = each.key
}

resource "aws_eks_access_entry" "karpenter_nodes" {
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.karpenter_node.arn
  type          = "EC2_LINUX"
}


# -----------------------------------------------------------------------------
# Karpenter controller permissions (IRSA policy) - based on upstream CloudFormation
# -----------------------------------------------------------------------------
# why is the ctrl policy SO LONG?: https://github.com/aws/karpenter-provider-aws/blob/main/website/content/en/docs/getting-started/getting-started-with-karpenter/cloudformation.yaml

resource "aws_iam_role" "karpenter_controller" {
  name = "${var.cluster_name}-karpenter-ctrl-role"
  assume_role_policy = templatefile("${path.module}/../resources/karpenter/ctrl_trust_policy.json", {
    OIDC_PROVIDER_ARN      = var.oidc_provider_arn
    OIDC_PROVIDER_HOSTPATH = replace(data.aws_iam_openid_connect_provider.eks.url, "https://", "")
  })
}

# These are the actual permissions of the controller
resource "aws_iam_policy" "karpenter_controller" {
  name = "${var.cluster_name}-karpenter-ctrl-policy"

  policy = templatefile(
    "${path.module}/../resources/karpenter/ctrl_policy.json",
    {
      AWS_REGION    = var.aws_region
      CLUSTER_NAME  = var.cluster_name
      ACCOUNT_ID    = data.aws_caller_identity.current.account_id
      IRQ_QUEUE_ARN = aws_sqs_queue.karpenter_irq.arn
      NODE_ROLE_ARN = aws_iam_role.karpenter_node.arn
    }
  )
}

resource "aws_iam_role_policy_attachment" "karpenter_controller" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.karpenter_controller.arn
}