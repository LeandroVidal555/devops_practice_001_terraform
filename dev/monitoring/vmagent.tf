resource "helm_release" "vmagent" {
  depends_on = [helm_release.victoria_metrics]

  name       = "vmagent"
  chart      = "victoria-metrics-agent"
  repository = "https://victoriametrics.github.io/helm-charts/"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name
  version    = var.vmagent_chart_version

  values = [templatefile("${var.values_path}/vmagent.yml", {
    remote_write_url    = "http://victoria-metrics-victoria-metrics-single-server.${var.monitoring_namespace}.svc:8428/api/v1/write"
    vmagent_persistence = var.vmagent_persistence
    buffer_size_gi      = var.vmagent_buffer_size_gi
    scrape_interval     = var.vmagent_scrape_interval
  })]
}