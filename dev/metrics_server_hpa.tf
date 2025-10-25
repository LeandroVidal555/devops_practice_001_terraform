resource "helm_release" "metrics_server" {
  name       = "${var.env}-${var.common_prefix}-metrics-server"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = var.met_srv_chart_version

  set {
    name  = "args[0]"
    value = "--kubelet-preferred-address-types=InternalIP,Hostname,ExternalIP"
  }
}
