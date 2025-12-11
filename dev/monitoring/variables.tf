variable "monitoring_namespace" { type = string }
variable "values_path" { type = string }

# VM
variable "vm_chart_version" { type = string }
variable "vm_persistence" { type = bool }
variable "vm_storage_size_gi" { type = number }
variable "vm_retention_months" { type = number }
variable "vmagent_chart_version" { type = string }
variable "vmagent_persistence" { type = bool }
variable "vmagent_buffer_size_gi" { type = number }
variable "vmagent_scrape_interval" { type = string }
variable "kube_state_metrics_chart_version" { type = string }
variable "node_exporter_chart_version" { type = string }

# GRAFANA
variable "grafana_chart_version" { type = string }
variable "grafana_admin_password" { type = string }
variable "grafana_persistence" { type = bool }
variable "grafana_storage_size_gi" { type = number }

# LOKI
variable "loki_chart_version" { type = string }
variable "loki_persistence" { type = bool }
variable "loki_storage_size_gi" { type = number }
variable "promtail_chart_version" { type = string }