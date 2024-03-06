################################################################################
# alb
################################################################################
module "alb" {
  source                     = "terraform-aws-modules/alb/aws"
  version                    = "9.7.0"
  name                       = "wp-alb-${var.environment}"
  vpc_id                     = data.terraform_remote_state.vpc.outputs.vpc_id
  subnets                    = data.terraform_remote_state.vpc.outputs.public_subnets
  enable_deletion_protection = var.environment == "dev" ? false : true
  # Security Group
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    },
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPs web traffic"
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

resource "aws_lb_target_group" "ip" {
  name        = "wp-alb-tg-${var.environment}"
  port        = local.listener_port
  protocol    = local.listener_protocol
  target_type = local.target_type
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  stickiness {
    type            = "lb_cookie"
    enabled         = true
    cookie_duration = 3600
  }

  health_check {
    enabled             = local.tg_health_check.enabled
    healthy_threshold   = local.tg_health_check.healthy_threshold
    interval            = local.tg_health_check.interval
    matcher             = local.tg_health_check.matcher
    path                = local.tg_health_check.path
    port                = local.listener_port
    protocol            = local.listener_protocol
    timeout             = local.tg_health_check.timeout
    unhealthy_threshold = local.tg_health_check.unhealthy_threshold

  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = module.alb.arn
  port              = local.listener_port
  protocol          = local.listener_protocol


  default_action {
    type = "redirect"
    redirect {
      port        = local.listener_https_port
      protocol    = local.listener_https_protocol
      status_code = "HTTP_301"
    }
  }
}


resource "aws_lb_listener" "front_end_https" {
  load_balancer_arn = module.alb.arn
  port              = local.listener_https_port
  protocol          = local.listener_https_protocol
  certificate_arn   = "arn_of_your_certificate"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Invalid hostname"
      status_code  = "401"
    }
  }
}

resource "aws_lb_listener_rule" "static" {
  listener_arn = aws_lb_listener.front_end.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ip.arn
  }


  condition {
    host_header {
      values = ["examplewp.com"]
    }
  }
}

################################################################################
# alb record
################################################################################

resource "aws_route53_record" "lb_wordpress_ael" {
  zone_id = data.terraform_remote_state.vpc.outputs.zone_id
  name    = "www.example.wp"
  type    = "CNAME"
  ttl     = "300"
  records = [module.alb.dns_name]
}

################################################################################
# cloudfront for wordpress
################################################################################

module "cloudfront_wordpress" {
  source               = "soroush/cloudfront_wordpress/aws"
  version              = "2.0.1"
  cnames               = ["www.examplewp.com"]
  domain_name          = "examplewp.com"
  origin_id            = "E22XRTe7wQ72"
  origin_ssl_protocols = ["TLSv1.2"]
  enabled              = true
  acm_certificate_arn  = "arn of your certificate here"
  tags = {
    Environment = var.environment
  }
}

#https://registry.terraform.io/modules/soroushatarod/cloudfront-wordpress/aws/latest - module preficongured for a wordpress cdn distribution 