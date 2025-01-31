provider "aws" {
  region = var.aws_region
}

resource "aws_ecs_cluster" "qa_cluster" {
  name = var.cluster_name
}

resource "aws_ecr_repository" "qa_repository" {
  name = var.repository_name
}
