module "db" {
  source                      = "terraform-aws-modules/rds/aws"
  identifier                  = "rds-wordpress"
  allocated_storage           = var.environment == "dev" ? local.allocated_storage : local.allocated_storage_prod
  engine                      = local.engine
  engine_version              = local.engine_version
  instance_class              = var.environment == "dev" ? local.instance_class : local.instance_class_prod
  family                      = local.family
  multi_az                    = var.environment == "dev" ? false : true
  db_name                     = local.db_name
  username                    = local.username
  port                        = local.db_port
  major_engine_version        = local.major_engine_version
  vpc_security_group_ids      = [aws_security_group.rds.id]
  skip_final_snapshot         = var.environment == "dev" ? true : false
  create_db_subnet_group      = false
  manage_master_user_password = false ##in a prod environment password rotation is the best choice also for securities reason of having a password in the tfstate
  password                    = random_password.password.result
  db_subnet_group_name        = data.terraform_remote_state.vpc.outputs.database_subnet_group_name

  tags = {
    Environment = var.environment
  }

}

resource "aws_security_group" "rds" {
  name        = "rds-sg-${var.environment}"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  description = "Allow mysql port"
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}


##db password generation and ssm value creation##
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_ssm_parameter" "mysql_db_password" {
  name  = "rds-wp-pass-${var.environment}"
  type  = "SecureString"
  value = random_password.password.result
}