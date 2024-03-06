################################################################################
# Cluster
################################################################################

module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "5.9.1"

  cluster_name = local.cluster_name

  # Capacity provider
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
        base   = 20
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }

}

################################################################################
# task definition
################################################################################
resource "aws_ecs_task_definition" "this" {
  family             = "wordpress"
  execution_role_arn = module.ecs_task_execution_role.this_iam_role_arn
  task_role_arn      = module.ecs_task_role.this_iam_role_arn
  network_mode       = "awsvpc"
  cpu                = 2048
  memory             = 4096
  container_definitions = templatefile("./resources/wp-task.tpl",
    {

      wordpress_db_host     = "${data.terraform_remote_state.rds.outputs.db_endpoint}"
      wordpress_db_user     = "${data.terraform_remote_state.rds.outputs.db_username}"
      wordpress_db_name     = "${data.terraform_remote_state.rds.outputs.db_name}"
      wordpress_db_password = "${data.terraform_remote_state.rds.outputs.db_password_parameter_arn}"
      container_port        = local.container_port
      region                = var.region
      container_name        = local.container_name
      container_image       = local.container_image
      wp_content_path       = local.wp_content_path
    }
  )
  requires_compatibilities = ["FARGATE"] #TO-DO create variable list of string

  volume {
    name = "efs"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.this.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.wp_content.id
        iam             = "DISABLED"
      }
    }
  }

}

resource "aws_security_group" "task_security_group" {
  name_prefix = "wp-task-sg-${var.environment}"
  description = "sg for ecs fargate tasks"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
}

resource "aws_security_group_rule" "grant_access_rds" {
  type                     = "ingress"
  from_port                = data.terraform_remote_state.rds.outputs.rds_port
  to_port                  = data.terraform_remote_state.rds.outputs.rds_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.task_security_group.id
  security_group_id        = data.terraform_remote_state.rds.outputs.rds_sg_id
}

###rule task
resource "aws_security_group_rule" "access_to_task_alb" {
  type                     = "ingress"
  from_port                = local.container_port
  to_port                  = local.container_port
  source_security_group_id = data.terraform_remote_state.frontend.outputs.alb-sg_id
  security_group_id        = aws_security_group.task_security_group.id
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "grant_access_to_efs_from_service" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.task_security_group.id
  security_group_id        = module.efs_sg.security_group_id
}

################################################################################
# service
################################################################################

resource "aws_ecs_service" "this" {
  name                               = local.container_name
  enable_execute_command             = true
  cluster                            = module.ecs_cluster.cluster_arn
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 50
  desired_count                      = 2
  task_definition                    = aws_ecs_task_definition.this.arn

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 0
  }

  load_balancer {
    target_group_arn = data.terraform_remote_state.frontend.outputs.alb-target_group_arn
    container_name   = local.container_name
    container_port   = local.container_port
  }

  network_configuration {
    subnets         = data.terraform_remote_state.vpc.outputs.private_subnets
    security_groups = [aws_security_group.task_security_group.id]
  }

}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/wordpress-logs"
  retention_in_days = 7
}

################################################################################
# EFS
################################################################################

resource "aws_efs_file_system" "this" {
  creation_token = "$aws-app-token-${var.environment}"

  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  encrypted  = true
  kms_key_id = aws_kms_key.this.arn

  lifecycle_policy {
    transition_to_ia = "AFTER_7_DAYS"
  }

  lifecycle_policy {
    # https://github.com/hashicorp/terraform-provider-aws/issues/21862
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  tags = {
    Environment = var.environment

  }
}

resource "aws_kms_key" "this" {
  description = "aws-app-efs key"
  key_usage   = "ENCRYPT_DECRYPT"
}


resource "aws_efs_access_point" "wp_content" {
  file_system_id = aws_efs_file_system.this.id
  posix_user {
    uid = 33 #www-data
    gid = 33 #www-data
  }

  root_directory {
    creation_info {
      owner_uid   = 33 #www-data
      owner_gid   = 33 #www-data
      permissions = 755
    }
    path = local.wp_content_path
  }

  tags = {
    Environment = var.environment
  }
}

module "efs_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.4.0"

  name        = "efs-container-sg"
  description = "Security group per accesso efs dai container"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id


  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]
}


resource "aws_efs_mount_target" "this" {
  count           = length(data.terraform_remote_state.vpc.outputs.private_subnets)
  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = data.terraform_remote_state.vpc.outputs.private_subnets[count.index]
  security_groups = [module.efs_sg.security_group_id]
}
