resource "helm_release" "grafana" {
  depends_on = [helm_release.vmagent]

  name       = "grafana"
  chart      = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name
  version    = var.grafana_chart_version

  values = [templatefile("${var.values_path}/grafana.yml", {
    admin_password      = var.grafana_admin_password
    vm_url              = "http://victoria-metrics-victoria-metrics-single-server.${var.monitoring_namespace}.svc:8428"
    loki_url            = "http://loki.${var.monitoring_namespace}.svc:3100"
    grafana_persistence = var.grafana_persistence
    storage_size_gi     = var.grafana_storage_size_gi
  })]
}