module "cluster_autoscaler_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "6.2.3"

  name = "${module.eks.cluster_name}-autoscaler"

  attach_cluster_autoscaler_policy = true

  oidc_providers = {
    this = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:cluster-autoscaler"]
    }
  }
}

resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  namespace  = "kube-system"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = var.ca_chart_version

  values = [
    yamlencode({
      autoDiscovery = {
        clusterName = module.eks.cluster_name
      }
      awsRegion     = var.aws_region
      cloudProvider = "aws"
      rbac = {
        serviceAccount = {
          create = true
          name   = "cluster-autoscaler"
          annotations = {
            "eks.amazonaws.com/role-arn" = module.cluster_autoscaler_irsa.arn
          }
        }
      }
      extraArgs = {
        skip-nodes-with-system-pods   = false
        skip-nodes-with-local-storage = false
        balance-similar-node-groups   = true
        node-group-auto-discovery : "asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/${module.eks.cluster_name}"
      }
      extraDeploy = [<<-YAML
        apiVersion: policy/v1
        kind: PodDisruptionBudget
        metadata:
        name: cluster-autoscaler
        namespace: kube-system
        spec:
        minAvailable: 1
        selector:
            matchLabels:
            app.kubernetes.io/name: cluster-autoscaler
        YAML
      ]
    })
  ]

  depends_on = [
    module.cluster_autoscaler_irsa,
    module.eks
  ]
}
