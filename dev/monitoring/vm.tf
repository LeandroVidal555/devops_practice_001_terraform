resource "helm_release" "victoria_metrics" {
  name       = "victoria-metrics"
  chart      = "victoria-metrics-single"
  repository = "https://victoriametrics.github.io/helm-charts/"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name
  version    = var.vm_chart_version

  values = [templatefile("${var.values_path}/vm.yml", {
    storage_size_gi   = var.vm_storage_size_gi
    retention_period  = var.vm_retention_months
  })]

  depends_on = [kubernetes_namespace_v1.monitoring]
}