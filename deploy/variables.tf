variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "eu-north-1"
}

variable "binance_ed25519_api_key" {
  description = "The Binance API key (gotten when ED25519 pubkey uploaded to Binance)"
  type        = string
  sensitive   = true
}

variable "binance_ed25519_private_key" {
  description = "The private part of ED25519 key uploaded to Binance"
  type        = string
  sensitive   = true
}

# variable "cluster_name" {
#   description = "The name of the ECS cluster"
#   type        = string
#   default     = "qa-cluster"
# }

# variable "repository_name" {
#   description = "The name of the ECR repository"
#   type        = string
#   default     = "qa-repository"
# }

# variable "service_name" {
#   description = "The name of the ECS service"
#   type        = string
#   default     = "qa-service"
# }

# variable "task_definition_family" {
#   description = "The family of the ECS task definition"
#   type        = string
#   default     = "qa-task"
# }

# variable "container_name" {
#   description = "The name of the ECS container"
#   type        = string
#   default     = "qa-container"
# }
