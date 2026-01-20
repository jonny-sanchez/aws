terraform {
  backend "s3" {
    bucket               = "alisa-shared-terraform-state"
    region               = "us-east-2"
    key                  = "backend.tfstate"
    workspace_key_prefix = "alisa-iam-identity-center"
    dynamodb_table       = "terraform-lock"
  }
}
