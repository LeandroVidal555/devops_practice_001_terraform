variable "aws_region" {
    description = "AWS region"
    type        = string
}

variable "aws_acc_id" {
    description = "AWS Account ID"
    type        = string
}

variable "common_prefix" {
    description = "Name prefix for the project"
    type        = string
}

variable "env" {
    description = "Environment"
    type        = string
}

variable "ecr_repos" {
    type = map(object({
        image_tag_mutability = string
        scan_on_push         = bool
    }))
}