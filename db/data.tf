data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket  = "pinulito-shared-terraform-state"
    key     = "pinulito-network/${terraform.workspace}/backend.tfstate"
    region  = "us-east-2"
    profile  = "alisa-shared"
  }
}