resource "helm_release" "promtail" {
  depends_on = [
    helm_release.loki,
    kubernetes_priority_class_v1.daemon_critical
  ]

  name       = "promtail"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "promtail"
  namespace  = var.monitoring_namespace
  version    = var.promtail_chart_version

  values = [templatefile("${var.values_path}/promtail.yml", {
    loki_url            = "http://loki.${var.monitoring_namespace}.svc:3100/loki/api/v1/push"
    priority_class_name = kubernetes_priority_class_v1.daemon_critical.metadata[0].name
  })]
}