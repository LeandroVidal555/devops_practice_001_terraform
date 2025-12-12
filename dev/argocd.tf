resource "kubernetes_namespace_v1" "argocd" {
  metadata { name = "argocd" }
}

resource "helm_release" "argocd" {
  depends_on = [
    module.mng_workers,
    kubernetes_namespace_v1.argocd,
    helm_release.aws_load_balancer_controller # avoid race condition
  ]

  name             = "${var.env}-${var.common_prefix}-argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  namespace        = "argocd"
  create_namespace = false
  timeout          = 600

  # Robust deployments
  atomic            = true
  cleanup_on_fail   = true
  dependency_update = true
  wait              = true
  #replace = true

  # Safe defaults for a private cluster:
  values = [
    yamlencode({
      installCRDs = true

      global = {
        # Settings for all subcharts
      }

      server = {
        # Keep private with ClusterIP; access via port-forward first
        service = {
          type = "ClusterIP"
        }
        extraArgs = ["--insecure"] # TLS is terminated at the ALB

        ingress = {
          enabled          = true
          ingressClassName = "alb"
          hostname         = "argo.${var.env}.${var.domain}"

          annotations = {
            "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
            "alb.ingress.kubernetes.io/target-type"      = "ip"
            "alb.ingress.kubernetes.io/healthcheck-path" = "/healthz"
            "alb.ingress.kubernetes.io/group.name"       = "${var.env}-argocd"
            "alb.ingress.kubernetes.io/listen-ports"     = "[{\"HTTPS\":443}]"
            "alb.ingress.kubernetes.io/certificate-arn"  = var.acm_cert_arn
          }

          paths = [
            # UI/API over HTTP (TLS already at ALB)
            {
              path     = "/"
              pathType = "Prefix"
              backend  = { serviceName = "argocd-server", servicePort = 80 }
            }
          ]
        }
      }

      # Reduce noise
      notifications = {
        enabled = false
      }
      # Dex is an identity service used by Argo CD for SSO (OIDC).
      dex = {
        enabled = false
      }
      # Disabled unless we want an external Redis
      redis = {
        enabled = true
      }
      controller = {
        metrics = { enabled = false } # Disabling metrics exporter saves resources if you’re not scraping Prometheus
      }
      repoServer = {
        metrics = { enabled = false } # Also disables metrics exporter too
      }
    })
  ]
}

resource "kubernetes_manifest" "argocd_root_app" {
  depends_on = [ helm_release.argocd ]

  manifest = yamldecode(
    templatefile("${path.module}/resources/argocd_root_app.yml.tpl", {
      env       = var.env
      repo_org  = local.argocd.repo_org
      repo_name = local.argocd.repo_name
      apps_path = local.argocd.apps_path
    })
  )
}