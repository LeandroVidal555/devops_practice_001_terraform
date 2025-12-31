resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  namespace  = var.monitoring_namespace
  version    = var.loki_chart_version

  values = [templatefile("${var.values_path}/loki.yml", {
    loki_persistence     = var.loki_persistence
    loki_storage_size_gi = var.loki_storage_size_gi
  })]
}