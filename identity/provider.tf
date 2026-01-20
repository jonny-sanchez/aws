terraform {
  required_version = ">= 1.14.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.27.0"
    }
  }
}
provider "aws" {
  region              = "us-east-2"
  allowed_account_ids = ["164885464039"]
  default_tags {
    tags = {
      Workspace = terraform.workspace
      Env       = "All"
      Terraform = "true"
    }
  }
}


