locals {
  cluster_name    = "app-cluster-${var.environment}"
  container_port  = 80
  container_name  = "wordpress"
  container_image = "wordpress:6.0.3"
  wp_content_path = "/var/www/html/wp-content"
}