module "ecr" {
  for_each = local.ecr_repos
  source   = "./ecr"

  repo_name            = "${var.common_prefix}-${each.key}"
  force_delete         = each.value.force_delete
  image_tag_mutability = each.value.image_tag_mutability
  scan_on_push         = each.value.scan_on_push

}

module "ec2_bastion" {
  source = "./ec2_bastion"

  name                        = "${var.env}-${var.common_prefix}-bastion"
  instance_type               = local.bastion.instance_type
  architecture                = local.bastion.architecture
  ami_regex                   = local.bastion.ami_regex
  subnet_id                   = local.bastion.subnet_id
  user_data_file              = local.bastion.user_data_file
  user_data_replace_on_change = local.bastion.user_data_replace_on_change
  policy_file                 = local.bastion.policy_file
  vpc_id                      = module.vpc.vpc_id
}

module "monitoring" {
  count  = var.deploy_monitoring ? 1 : 0
  source = "./monitoring"

  monitoring_namespace = local.monitoring.monitoring_namespace
  values_path          = local.monitoring.values_path

  vm_chart_version                 = local.monitoring.vm.vm_chart_version
  vm_storage_size_gi               = local.monitoring.vm.vm_storage_size_gi
  vm_retention_months              = local.monitoring.vm.vm_retention_months
  vmagent_chart_version            = var.vmagent_chart_version
  vmagent_buffer_size_gi           = local.monitoring.vm.vmagent_buffer_size_gi
  vmagent_scrape_interval          = local.monitoring.vm.vmagent_scrape_interval
  kube_state_metrics_chart_version = var.kube_state_metrics_chart_version
  node_exporter_chart_version      = var.node_exporter_chart_version

  grafana_chart_version   = local.monitoring.grafana.grafana_chart_version
  grafana_admin_password  = local.monitoring.grafana.grafana_admin_password
  grafana_persistence     = local.monitoring.grafana.grafana_persistence
  grafana_storage_size_gi = local.monitoring.grafana.grafana_storage_size_gi
}