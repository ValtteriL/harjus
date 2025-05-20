output "ecr_url" {
  description = "URL to the ECR repository"
  value       = aws_ecr_repository.ecr_repository.repository_url
}


output "instance_ip" {
  description = "The public dns address of the EC2 instance"
  value       = aws_instance.instance.public_dns
}
