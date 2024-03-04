##route53##
resource "aws_route53_record" "lb_wordpress_ael" {
  zone_id = data.terraform_remote_state.vpc.outputs.zone_id
  name    = local.record_name
  type    = "CNAME"
  ttl     = "300"
  records = [module.alb.dns_name]
}

##ALB##
module "alb" {
  source                     = "terraform-aws-modules/alb/aws"
  version                    = "9.7.0"
  name                       = "wp-alb-${var.environment}"
  vpc_id                     = data.terraform_remote_state.vpc.outputs.vpc_id
  subnets                    = data.terraform_remote_state.vpc.outputs.public_subnets
  enable_deletion_protection = var.environment == "dev" ? true : false
  # Security Group
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  tags = {
    Environment = var.environment
  }

}