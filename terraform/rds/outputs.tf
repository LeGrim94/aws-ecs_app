output "db_password_parameter" {
  description = "DB Password Parameter"
  value       = aws_ssm_parameter.mysql_db_password.name
}

output "db_password_parameter_arn" {
  description = "ARN of DB Password Parameter"
  value       = aws_ssm_parameter.mysql_db_password.arn
}

output "db_endpoint" {
  description = "DB Endpoint"
  value       = module.db.db_instance_endpoint
}

output "db_username" {
  description = "DB username"
  value       = module.db.db_instance_username
  sensitive   = true
}

output "db_name" {
  description = "DB name"
  value       = module.db.db_instance_name
}

output "rds_sg_id" {
  description = "DB Security Group ID"
  value       = aws_security_group.rds.id
}

output "rds_port" {
  description = "Port used by the DB"
  value       = module.db.db_instance_port
}
