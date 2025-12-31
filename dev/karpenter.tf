data "aws_partition" "current" {}

data "aws_iam_openid_connect_provider" "eks" {
  arn = module.eks.oidc_provider_arn
}

# Node SG tagging for discovery
resource "aws_ec2_tag" "karpenter_node_sg_discovery" {
  resource_id = module.eks.node_security_group_id
  key         = "karpenter.sh/discovery"
  value       = module.eks.cluster_name
}

resource "kubernetes_namespace_v1" "karpenter" {
  metadata { name = "karpenter" }
}

resource "helm_release" "karpenter" {
  depends_on = [
    kubernetes_namespace_v1.karpenter,
    aws_iam_role_policy_attachment.karpenter_controller,
    module.mng_bootstrap,
    aws_eks_access_entry.karpenter_nodes,
    aws_ec2_tag.karpenter_node_sg_discovery,
    aws_cloudwatch_event_target.karpenter_scheduled_change,
    aws_cloudwatch_event_target.karpenter_spot_irq,
    aws_cloudwatch_event_target.karpenter_rebalance,
    aws_cloudwatch_event_target.karpenter_instance_state_change,
  ]

  name             = "karpenter"
  namespace        = "karpenter"
  create_namespace = false

  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = var.karpenter_chart_version

  values = [
    yamlencode({
      settings = {
        clusterName       = module.eks.cluster_name
        interruptionQueue = aws_sqs_queue.karpenter_irq.name
      }

      serviceAccount = {
        create = true
        name   = local.karpenter.service_account
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.karpenter_controller.arn
        }
      }
    })
  ]
}