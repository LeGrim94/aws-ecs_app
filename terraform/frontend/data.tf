data "terraform_remote_state" "vpc" {
  backend = "local"

  config = {
    path = "${path.module}/../network/terraform.tfstate"
  }
}