
terraform {
  backend "s3" {
    bucket               = "pinulito-shared-terraform-state"
    region               = "us-east-2"
    key                  = "backend.tfstate"
    workspace_key_prefix = "alisa-vpn"
    dynamodb_table       = "terraform-lock"
  }
}

