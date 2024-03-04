module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = local.name
  cidr = local.cidr

  azs              = ["${var.region}a", "${var.region}b"]
  private_subnets  = local.private_subnets
  public_subnets   = local.public_subnets
  database_subnets = local.database_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = var.environment == "dev" ? true : false
  enable_dns_hostnames = true


  tags = {
    Environment = var.environment
  }

}

#private hosted_zone
resource "aws_route53_zone" "private" {
  name = local.hosted_zone_name
  vpc {
    vpc_id = module.vpc.vpc_id
  }
}