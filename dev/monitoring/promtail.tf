resource "helm_release" "promtail" {
  name       = "promtail"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "promtail"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name
  version    = var.promtail_chart_version

  depends_on = [
    helm_release.loki # ensure Loki exists before Promtail tries to push logs
  ]

  values = [templatefile("${var.values_path}/promtail.yml", {
    loki_url = "http://loki.${var.monitoring_namespace}.svc:3100/loki/api/v1/push"
  })]
}