# main.tf (or observability/main.tf)
resource "helm_release" "node_exporter" {
  depends_on = [kubernetes_namespace_v1.monitoring]
  
  name       = "node-exporter"
  chart      = "prometheus-node-exporter"
  repository = "https://prometheus-community.github.io/helm-charts"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name
  version    = var.node_exporter_chart_version
}