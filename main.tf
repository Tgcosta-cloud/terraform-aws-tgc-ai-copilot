terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}


data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}


