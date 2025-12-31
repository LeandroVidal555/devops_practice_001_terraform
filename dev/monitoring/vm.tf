resource "helm_release" "victoria_metrics" {
  name       = "victoria-metrics"
  chart      = "victoria-metrics-single"
  repository = "https://victoriametrics.github.io/helm-charts/"
  namespace  = var.monitoring_namespace
  version    = var.vm_chart_version

  values = [templatefile("${var.values_path}/vm.yml", {
    vm_persistence   = var.vm_persistence
    storage_size_gi  = var.vm_storage_size_gi
    retention_period = var.vm_retention_months
  })]
}