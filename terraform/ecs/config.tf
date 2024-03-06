provider "aws" {
  default_tags {
    tags = {
      Terraform = "true"
      Project   = "ecs_wordpress"
      Service   = "ecs"
    }
  }
}