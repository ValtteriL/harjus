output "instance_ip" {
  description = "The public dns address of the EC2 instance"
  value       = aws_instance.instance.public_dns
}

output "artifact_bucket_name" {
  description = "The name of the artifact S3 bucket"
  value       = aws_s3_bucket.artifact_bucket.id
}
