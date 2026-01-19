variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "ap-northeast-1"
}

variable "availability_zone" {
  description = "The AWS availability zone to deploy the EC2 instance in (e.g., ap-northeast-1a). Run `just deploy::measure-latency` to find the optimal AZ."
  type        = string
  default = "ap-northeast-1a"
}

variable "s3_bucket_name" {
  description = "The name of the S3 bucket to create for Terraform state storage"
  type        = string
  default = "replaceme"
}

variable "s3_bucket_region" {
  description = "The AWS region where the S3 bucket for Terraform state storage will be created"
  type        = string
  default     = "eu-north-1"
}