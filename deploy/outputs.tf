output "ecr_url" {
  description = "URL to the ECR repository"
  value       = aws_ecr_repository.ecr_repository.repository_url
}

# output "ecs_cluster_name" {
#   description = "The name of the ECS cluster"
#   value       = aws_ecs_cluster.qa_cluster.name
# }

# output "ecr_repository_url" {
#   description = "The URL of the ECR repository"
#   value       = aws_ecr_repository.qa_repository.repository_url
# }

# output "ecs_service_name" {
#   description = "The name of the ECS service"
#   value       = aws_ecs_service.qa_service.name
# }

# output "ecs_task_definition_arn" {
#   description = "The ARN of the ECS task definition"
#   value       = aws_ecs_task_definition.qa_task.arn
# }
