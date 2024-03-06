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



################################################################################
# SSM
################################################################################
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

################################################################################
# RDS Bastion
################################################################################

module "asg" {
  source = "terraform-aws-modules/autoscaling/aws"

  # Autoscaling group
  name = "aws-app-bastion-${var.environment}"

  min_size                  = 0
  max_size                  = 1
  desired_capacity          = 1
  wait_for_capacity_timeout = 0
  health_check_type         = "EC2"
  vpc_zone_identifier       = data.terraform_remote_state.vpc.outputs.private_subnets

  initial_lifecycle_hooks = [
    {
      name                  = "ExampleStartupLifeCycleHook"
      default_result        = "CONTINUE"
      heartbeat_timeout     = 60
      lifecycle_transition  = "autoscaling:EC2_INSTANCE_LAUNCHING"
      notification_metadata = jsonencode({ "hello" = "world" })
    },
    {
      name                  = "ExampleTerminationLifeCycleHook"
      default_result        = "CONTINUE"
      heartbeat_timeout     = 180
      lifecycle_transition  = "autoscaling:EC2_INSTANCE_TERMINATING"
      notification_metadata = jsonencode({ "goodbye" = "world" })
    }
  ]

  # Launch template
  launch_template_name        = "aws-app-${var.environment}-template"
  launch_template_description = "aws launch template for rds bastion"
  update_default_version      = true
  user_data                   = filebase64("./resources/ec2_userdata.sh")
  image_id                    = local.image_id
  instance_type               = local.instance_type
  ebs_optimized               = true
  enable_monitoring           = true

  # IAM role & instance profile
  create_iam_instance_profile = true
  iam_role_name               = "aws-app-asg_role"
  iam_role_path               = "/ec2/"
  iam_role_description        = "IAM role for rds bastion"
  iam_role_tags = {
    CustomIamRole = "Yes"
  }
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  block_device_mappings = [
    {
      # Root volume
      device_name = "/dev/xvda"
      no_device   = 0
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = local.allocated_bastion_storage
        volume_type           = "gp2"
      }
    }
  ]

  network_interfaces = [
    {
      delete_on_termination = true
      description           = "eth0"
      device_index          = 0
      security_groups       = [aws_security_group.bastion.id]
    },
  ]

  tags = {
    Environment = var.environment
  }
}

resource "aws_security_group" "bastion" {
  name        = "bastion-sg-${var.environment}"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  description = "bastion sg"
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group_rule" "grant_access_bastion" {
  type                     = "ingress"
  from_port                = local.db_port
  to_port                  = local.db_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.rds.id

}