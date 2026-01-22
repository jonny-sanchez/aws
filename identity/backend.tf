terraform {
  backend "s3" {
    bucket               = "pinulito-shared-terraform-state"
    region               = "us-east-2"
    key                  = "backend.tfstate"
    workspace_key_prefix = "pinulito-iam-identity-center"
    dynamodb_table       = "terraform-lock"
  }
}
