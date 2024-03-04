locals {
    private_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
    public_subnets   = ["10.0.101.0/24", "10.0.102.0/24"]
    database_subnets = ["10.0.103.0/24", "10.0.104.0/24"]
    cidr = "10.0.0.0/16"
    name= "aws_app-vpc-${var.environment}"
    hosted_zone_name= "aws_app-zone-${var.environment}"
}