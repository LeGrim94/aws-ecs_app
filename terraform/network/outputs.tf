output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "Output of private subnet addresses"
  value       = module.vpc.private_subnets
}

output "database_subnets" {
  description = "Output of database subnet addresses"
  value       = module.vpc.database_subnets
}

output "database_subnet_group_name" {
  description = "Name of the database subnet group"
  value       = module.vpc.database_subnet_group_name
}

output "public_subnets" {
  description = "Public subnets of the VPC"
  value       = module.vpc.public_subnets
}

output "zone_id" {
  description = "private route53 zone id"
  value       = aws_route53_zone.primary.id
}