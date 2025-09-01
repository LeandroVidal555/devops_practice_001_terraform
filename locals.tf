locals {
  ecr_repos = {
    "app" = {
      image_tag_mutability = "MUTABLE"
      scan_on_push         = false
    }
  }
  eks_cluster = {
    endpoint_public_access  = false
    endpoint_private_access = true
    k8s_version             = "1.33"
    capacity_type           = "SPOT"
    instance_types          = ["t3a.small"]
    desired_size            = 1
    min_size                = 0
    max_size                = 2
    ami_type                = "AL2023_x86_64_STANDARD"
    disk_size               = 20
    admin_roles = [
      "aws-reserved/sso.amazonaws.com/AWSReservedSSO_AdministratorAccess_${var.admin_sso_role_hash}",
      "${var.env}-${var.common_prefix}-bastion-role"
    ]
  }
  bastion = {
    instance_type  = "t3a.micro"
    ami_id         = "resolve:ssm:/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
    subnet_id      = module.vpc.private_subnets[0]
    user_data_file = file("${path.module}/resources/user_data_bastion.sh")
    policy_file    = file("${path.module}/resources/ec2_bastion_role.json")
  }
}