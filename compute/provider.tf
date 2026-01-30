terraform {
  required_version = ">= 1.14.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.27.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "aws" {
  region              = local.config.region
  
  assume_role {
    role_arn = local.config.assume_role_arn
  }
  
  default_tags {
    tags = merge(
      local.config.tags,
      {
        Workspace = terraform.workspace
        Terraform = "true"
      }
    )
  }
}

