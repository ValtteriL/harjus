variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-west-2"
}

variable "cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
  default     = "qa-cluster"
}

variable "repository_name" {
  description = "The name of the ECR repository"
  type        = string
  default     = "qa-repository"
}
