resource "kubernetes_namespace_v1" "monitoring" {
  metadata { name = var.monitoring_namespace }
}

resource "kubernetes_priority_class" "daemon_critical" {
  metadata {
    name = "daemon-critical"
  }

  value         = 1000000000
  global_default = false
  description   = "Guaranteed DaemonSet scheduling on all nodes"
}