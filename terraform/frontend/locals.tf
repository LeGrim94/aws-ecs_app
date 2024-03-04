locals {
  record_name = "wp-record-${var.environment}"

  #listener/tg
  listener_port     = 80
  listener_protocol = "HTTP"
  target_type       = "ip"
  tg_health_check = {
    enabled             = true
    healthy_threshold   = 3
    interval            = 30
    matcher             = "200-399"
    path                = "/"
    timeout             = 6
    unhealthy_threshold = 2
  }

}