### EKS access entry - replaces aws-auth configmap management
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

resource "aws_eks_access_entry" "bootstrap_nodes" {
  count      = var.deploy_apps ? 0 : 1
  depends_on = [aws_iam_role.bootstrap_nodes_role]

  cluster_name  = module.eks.cluster_name
  principal_arn = aws_iam_role.bootstrap_nodes_role.arn
  type          = "EC2_LINUX"
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
  count = var.enable_public_api ? 1 : 0

  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  description       = "Github Actions to EKS API"
  security_group_id = module.eks.cluster_security_group_id
  cidr_blocks       = [var.github_actions_egress_cidr]
}