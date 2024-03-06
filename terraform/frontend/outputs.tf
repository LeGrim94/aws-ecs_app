output "alb-target_group_arn" {
  description = "arn of wp target group"
  value       = aws_lb_target_group.ip.arn
}

output "alb-sg_id" {
  description = "arn of wp target group"
  value       = module.alb.security_group_id
}