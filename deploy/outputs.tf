output "instance_ip" {
  description = "The public dns address of the EC2 instance"
  value       = aws_instance.instance.public_dns
}

output "availability_zone" {
  description = "The availability zone of the EC2 instance"
  value       = aws_instance.instance.availability_zone
}

output "dpdk_eip" {
  description = "The Elastic IP assigned to the DPDK interface"
  value       = aws_eip.dpdk_eip.public_ip
}