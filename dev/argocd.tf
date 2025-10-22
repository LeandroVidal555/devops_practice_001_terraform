resource "helm_release" "argocd" {
  depends_on = [module.mng_workers]

  name             = "${var.env}-${var.common_prefix}-argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  namespace        = "argocd"
  create_namespace = true
  timeout          = 600

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
        # Optional: turn on plaintext login for first access (TLS termination via Ingress/NLB later)
        extraArgs = ["--insecure"]
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
  count = var.deploy_apps ? 1 : 0

  manifest = yamldecode(
    templatefile("${path.module}/resources/argocd_root_app.yml.tpl", {
      env       = var.env
      repo_org  = local.argocd.repo_org
      repo_name = local.argocd.repo_name
      apps_path = local.argocd.apps_path
    })
  )
}