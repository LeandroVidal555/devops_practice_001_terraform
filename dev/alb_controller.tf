data "tls_certificate" "oidc_thumbprint" {
  url = module.eks.cluster_oidc_issuer_url
}

data "http" "alb_controller_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "alb_controller" {
  name        = "${var.env}-${var.common_prefix}-ALB_Controller"
  description = "IAM policy for AWS Load Balancer Controller"
  policy      = data.http.alb_controller_policy.response_body
}

# --- IRSA role for the controller SA ---
resource "aws_iam_role" "alb_controller" {
  name = "${local.eks_cluster.name}-ALB_Controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = ""
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
            "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "alb_attach" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}

# --- Helm chart install ---
resource "helm_release" "aws_load_balancer_controller" {
  name       = "${var.env}-${var.common_prefix}-albcont"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.albcont_chart_version
  namespace  = "kube-system"

  # Let Helm create the SA and annotate it with the IRSA role
  set = [
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.alb_controller.arn
    },
    {
      name  = "clusterName"
      value = local.eks_cluster.name
    },
    {
      name  = "region"
      value = var.aws_region
    }
  ]

  depends_on = [
    aws_iam_role_policy_attachment.alb_attach,
  ]
}
