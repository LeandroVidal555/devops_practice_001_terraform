module "ecr" {
  for_each = local.ecr_repos
  source   = "./ecr"

  repo_name            = "${var.common_prefix}-${each.key}"
  image_tag_mutability = each.value.image_tag_mutability
  scan_on_push         = each.value.scan_on_push

}

module "ec2_bastion" {
  source = "./ec2_bastion"

  name                        = "${var.env}-${var.common_prefix}-bastion"
  instance_type               = local.bastion.instance_type
  subnet_id                   = local.bastion.subnet_id
  user_data_file              = local.bastion.user_data_file
  user_data_replace_on_change = local.bastion.user_data_replace_on_change
  policy_file                 = local.bastion.policy_file
  vpc_id                      = module.vpc.vpc_id
}