resource "helm_release" "node_exporter" {
  name       = "node-exporter"
  chart      = "prometheus-node-exporter"
  repository = "https://prometheus-community.github.io/helm-charts"
  namespace  = var.monitoring_namespace
  version    = var.node_exporter_chart_version

  values = [
    templatefile("${var.values_path}/node_exporter.yml", {
      priority_class_name = kubernetes_priority_class_v1.daemon_critical.metadata[0].name
    })
  ]
}