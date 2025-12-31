# main.tf
resource "helm_release" "kube_state_metrics" {
  name       = "kube-state-metrics"
  chart      = "kube-state-metrics"
  repository = "https://prometheus-community.github.io/helm-charts"
  namespace  = var.monitoring_namespace
  version    = var.kube_state_metrics_chart_version
}