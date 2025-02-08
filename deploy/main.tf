terraform {
  # these come from the backend directory
  backend "s3" {
    encrypt        = true
    bucket         = "harjus-terraform-state20250208211637665900000001"
    key            = "path/to/state"
    region         = "eu-north-1"
    dynamodb_table = "terraform-lock"
  }
}

# resource "aws_ecs_cluster" "qa_cluster" {
#   name = var.cluster_name
# }

# resource "aws_ecr_repository" "qa_repository" {
#   name = var.repository_name
# }

# module "ecs_service" {
#   source                 = "./ecs_service.tf"
#   service_name           = var.service_name
#   task_definition_family = var.task_definition_family
#   container_name         = var.container_name
#   image_tag              = var.image_tag
#   subnets                = var.subnets
#   security_groups        = var.security_groups
# }
