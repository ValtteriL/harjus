variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "ap-northeast-1"
}

variable "availability_zone" {
  description = "The AWS availability zone to deploy the EC2 instance in (e.g., ap-northeast-1a). Run `just deploy::measure-latency` to find the optimal AZ."
  type        = string
}
