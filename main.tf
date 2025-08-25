#module "eks" {
#  source  = "terraform-aws-modules/eks/aws"
#  version = "~> 21.1.1"
# gptazo

#}

module "ecr" {
  for_each = var.ecr_repos
  source   = "./ecr"

  repo_name            = "${var.common_prefix}-${each.key}"
  image_tag_mutability = each.value.image_tag_mutability
  scan_on_push         = each.value.scan_on_push

}