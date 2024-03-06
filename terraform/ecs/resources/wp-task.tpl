[
  {
    "name": "${container_name}",
    "image": "${container_image}",
    "readonly_root_filesystem": false,
    "portMappings": [
                {
                    "hostPort": ${container_port},
                    "containerPort": ${container_port},
                    "protocol": "tcp"
                }],
    "environment": [
                {
                    "name": "WORDPRESS_DB_HOST",
                    "value": "${wordpress_db_host}"
                },
                {   
                    "name": "WORDPRESS_DB_USER",
                    "value": "${wordpress_db_user}"
                },
                {   
                    "name": "WORDPRESS_DB_NAME",
                    "value": "${wordpress_db_name}"
                }],

    "secrets": [{
      "name": "WORDPRESS_DB_PASSWORD",
      "valueFrom": "${wordpress_db_password}"
    }],
    "mountPoints": [
      {
        "containerPath": "${wp_content_path}",
        "sourceVolume": "efs"
      }
    ],
    "logConfiguration": {
      "logDriver":"awslogs",
      "options": {
        "awslogs-group": "/ecs/wordpress-logs",
        "awslogs-region": "${region}",
        "awslogs-stream-prefix": "wp"
      }
    }
  }
]