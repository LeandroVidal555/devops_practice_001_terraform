resource "helm_release" "loki" {
  depends_on = [kubernetes_namespace_v1.monitoring]

  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name
  version    = var.loki_chart_version

  values = [templatefile("${var.values_path}/loki.yml", {
    loki_persistence   = var.loki_persistence
    loki_storage_size_gi = var.loki_storage_size_gi
  })]
}