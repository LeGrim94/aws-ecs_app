################################################################################
# VPC
################################################################################

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = local.name
  cidr = local.cidr

  azs              = ["${var.region}a", "${var.region}b"]
  private_subnets  = local.private_subnets
  public_subnets   = local.public_subnets
  database_subnets = local.database_subnets

  enable_nat_gateway      = true
  single_nat_gateway      = var.environment == "dev" ? true : false
  enable_dns_hostnames    = true
  map_public_ip_on_launch = true
  enable_dns_support      = true


  tags = {
    Environment = var.environment
  }

}

resource "aws_route53_zone" "primary" {
  name = "examplewp.com"
}