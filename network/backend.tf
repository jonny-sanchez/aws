terraform {
  required_version = "1.14.0"
  backend "s3" {
    bucket               = "pinulito-shared-terraform-state"
    region               = "us-east-2"
    key                  = "backend.tfstate"
    workspace_key_prefix = "pinulito-network"
    dynamodb_table       = "terraform-lock"
    profile              = "alisa-shared"
  }
}