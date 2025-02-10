output "ecr_url" {
  description = "URL to the ECR repository"
  value       = aws_ecr_repository.ecr_repository.repository_url
}

output "deployed_image" {
  description = "The container image that was deployed"
  value       = "${aws_ecr_repository.ecr_repository.repository_url}:${var.image_tag}"
}
