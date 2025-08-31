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
  }
  bastion = {
    instance_type  = "t3a.micro"
    ami_id         = "ami-0b016c703b95ecbe4"
    subnet_id      = module.vpc.private_subnets[0]
    user_data_file = "${path.root}/resources/user_data_bastion.sh"
    policy_file    = "${path.root}/resources/ec2_bastion_role.sh"
  }
}