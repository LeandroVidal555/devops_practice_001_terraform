module "ecr" {
  for_each = local.ecr_repos
  source   = "./ecr"

  repo_name            = "${var.common_prefix}-${each.key}"
  image_tag_mutability = each.value.image_tag_mutability
  scan_on_push         = each.value.scan_on_push

}