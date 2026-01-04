data "aws_partition" "current" {}

data "aws_iam_openid_connect_provider" "eks" {
  arn = var.oidc_provider_arn
}

resource "kubernetes_namespace_v1" "karpenter" {
  metadata { name = "karpenter" }
}

resource "helm_release" "karpenter" {
  depends_on = [
    kubernetes_namespace_v1.karpenter,
    aws_iam_role_policy_attachment.karpenter_controller,
    aws_eks_access_entry.karpenter_nodes,
    aws_cloudwatch_event_target.karpenter_scheduled_change,
    aws_cloudwatch_event_target.karpenter_spot_irq,
    aws_cloudwatch_event_target.karpenter_rebalance,
    aws_cloudwatch_event_target.karpenter_instance_state_change,
  ]

  wait    = true # replaces mng_bootstrap dependency
  timeout = 900

  name             = "karpenter"
  namespace        = "karpenter"
  create_namespace = false

  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = var.karpenter_chart_version

  values = [
    yamlencode({
      settings = {
        clusterName       = var.cluster_name
        interruptionQueue = aws_sqs_queue.karpenter_irq.name
      }

      serviceAccount = {
        create = true
        name   = "karpenter"
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.karpenter_controller.arn
        }
      }

      # Remove chart default that blocks scheduling on karpenter nodes
      affinity = null

      # strongly recommended so Karpenter won’t voluntarily disrupt itself
      podAnnotations = {
        "karpenter.sh/do-not-disrupt" = "true"
      }
    })
  ]
}