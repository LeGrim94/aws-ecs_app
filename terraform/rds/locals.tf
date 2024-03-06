locals {
  allocated_storage      = 20
  allocated_storage_prod = 100
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.small"
  instance_class_prod    = "db.t4g.large"
  family                 = "mysql8.0"
  db_name                = "wp"
  username               = "root"
  db_port                = "3306"
  major_engine_version   = "8.0"

  ##bastion
  allocated_bastion_storage = 20
  image_id                  = "ami-0fc3317b37c1269d3"
  instance_type             = "t3.micro"
}