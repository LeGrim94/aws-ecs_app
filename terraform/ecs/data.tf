data "terraform_remote_state" "vpc" {
  backend = "local"

  config = {
    path = "${path.module}/../network/terraform.tfstate"
  }
}

data "terraform_remote_state" "rds" {
  backend = "local"

  config = {
    path = "${path.module}/../rds/terraform.tfstate"
  }
}

data "terraform_remote_state" "frontend" {
  backend = "local"

  config = {
    path = "${path.module}/../frontend/terraform.tfstate"
  }
}