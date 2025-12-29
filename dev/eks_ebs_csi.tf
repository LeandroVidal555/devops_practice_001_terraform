# IAM role for the EBS CSI controller SA
resource "aws_iam_role" "ebs_csi_controller" {
  name = "${module.eks.cluster_name}-ebs-csi-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = module.eks.oidc_provider_arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "${module.eks.oidc_provider}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_policy" {
  role       = aws_iam_role.ebs_csi_controller.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# Addon for dynamic storage creating/binding
resource "aws_eks_addon" "ebs_csi" {
  depends_on = [module.mng_bootstrap] # ensure nodes exist first

  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi_controller.arn

  configuration_values = jsonencode({
    controller = {
      nodeSelector = { "node-role" = "bootstrap" }
      tolerations = [{
        key      = "dedicated"
        operator = "Equal"
        value    = "system"
        effect   = "NoSchedule"
      }]
    }
    node = {
      tolerations = [{
        key      = "dedicated"
        operator = "Equal"
        value    = "system"
        effect   = "NoSchedule"
      }]
    }
  })
}

resource "kubernetes_storage_class_v1" "gp3_default" {
  depends_on = [aws_eks_addon.ebs_csi]

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type = "gp3"
  }

  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
}
