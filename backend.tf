terraform {
    backend "s3" {
        bucket  = "devops-practice-lmv"
        key     = "dp_001/terraform/tfstate/infra.tfstate"
        region  = "us-east-1"
        encrypt = true
    }
}