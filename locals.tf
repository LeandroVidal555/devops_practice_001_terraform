locals {
  ecr_repos = {
    "app" = {
      image_tag_mutability = "MUTABLE"
      scan_on_push         = false
    }
  }
}