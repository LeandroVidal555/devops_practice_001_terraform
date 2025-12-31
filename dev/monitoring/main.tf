resource "kubernetes_priority_class_v1" "daemon_critical" {
  metadata {
    name = "daemon-critical"
  }

  value          = 1000000000
  global_default = false
  description    = "Guaranteed DaemonSet scheduling on all nodes"
}