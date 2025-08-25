#### GENERAL ####
aws_region    = "us-east-1"
common_prefix = "dp-001"
env           = "dev"

#### ECR ####
ecr_repos = {
  "app" = {
    image_tag_mutability = "MUTABLE"
    scan_on_push         = false
  }
}