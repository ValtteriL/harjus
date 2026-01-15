terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

variable "target_host" {
  description = "Target hostname to measure latency to"
  type        = string
  default     = ""
}

variable "target_port" {
  description = "Target TCP port"
  type        = number
  default     = 0
}

variable "num_probes" {
  description = "Number of nping probes to send"
  type        = number
  default     = 100
}

# Get all available AZs in the region
data "aws_availability_zones" "available" {
  state = "available"
}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get default subnets for each AZ
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

data "aws_subnet" "default" {
  for_each = toset(data.aws_availability_zones.available.names)
  
  vpc_id            = data.aws_vpc.default.id
  availability_zone = each.value
  default_for_az    = true
}

# Create temporary key pair
resource "tls_private_key" "temp_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "temp_key" {
  key_name_prefix = "latency-measure-"
  public_key      = tls_private_key.temp_key.public_key_openssh
}

resource "local_sensitive_file" "temp_key_file" {
  content         = tls_private_key.temp_key.private_key_pem
  filename        = "${path.module}/latency-measure-key.pem"
  file_permission = "0400"
}

# Security group allowing SSH and all egress
resource "aws_security_group" "latency_measure" {
  name_prefix = "latency-measure-"
  description = "Temporary security group for latency measurement"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "latency-measure-sg"
  }
}

# EC2 instances in each AZ
resource "aws_instance" "latency_measure" {
  for_each = data.aws_subnet.default

  # debian-13-amd64-20250814-2204 - same as main.tf
  ami = "ami-01a89c4a177e76f46"

  instance_type          = "t3.micro"
  key_name               = aws_key_pair.temp_key.key_name
  vpc_security_group_ids = [aws_security_group.latency_measure.id]
  subnet_id              = each.value.id
  availability_zone      = each.key

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -qq
    apt-get install -y -qq nmap > /dev/null 2>&1
    touch /tmp/setup-complete
  EOF

  tags = {
    Name = "latency-measure-${each.key}"
  }
}

# Run nping on each instance and capture output
resource "terraform_data" "nping_results" {
  for_each = aws_instance.latency_measure

  depends_on = [aws_instance.latency_measure]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "admin"
      private_key = tls_private_key.temp_key.private_key_pem
      host        = each.value.public_ip
    }

    inline = [
      "echo 'Waiting for setup to complete...'",
      "while [ ! -f /tmp/setup-complete ]; do sleep 2; done",
      "echo ''",
      "echo '=== Latency measurement for ${each.key} ==='",
      "echo 'Target: ${var.target_host}:${var.target_port}'",
      "echo 'Probes: ${var.num_probes}'",
      "echo ''",
      "sudo nping -c ${var.num_probes} --tcp -p ${var.target_port} ${var.target_host} 2>&1 | tail -5",
      "echo ''"
    ]
  }
}

# Output AZ mapping for reference
output "availability_zone_mapping" {
  description = "Mapping of AZ names to AZ IDs"
  value = {
    for az in data.aws_availability_zones.available.names :
    az => data.aws_availability_zones.available.zone_ids[index(data.aws_availability_zones.available.names, az)]
  }
}

output "instances" {
  description = "Instances created for latency measurement"
  value = {
    for az, instance in aws_instance.latency_measure :
    az => {
      instance_id = instance.id
      public_ip   = instance.public_ip
    }
  }
}

output "instructions" {
  description = "Next steps after measurement"
  value       = "Run 'terraform destroy' to clean up all resources. Use the AZ with lowest avg RTT for deployment."
}
