# main.tf
resource "helm_release" "kube_state_metrics" {
  name       = "kube-state-metrics"
  chart      = "kube-state-metrics"
  repository = "https://prometheus-community.github.io/helm-charts"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name
  version    = var.kube_state_metrics_chart_version

  depends_on = [kubernetes_namespace_v1.monitoring]
}
