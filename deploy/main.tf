terraform {
  # these come from the backend directory
  backend "s3" {
    encrypt        = true
    bucket         = "harjus-terraform-state20250208211637665900000001"
    key            = "path/to/state"
    region         = "eu-north-1"
    dynamodb_table = "terraform-lock"
  }

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
  }
}

# resources required to SSH into the EC2 instance(s)

# allow ingress traffic to port 22
# allow all egress traffic
resource "aws_security_group" "security" {
  name = "allow_ingress_ssh_egress_all"

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec_key" {
  key_name_prefix = "harjus-ec2-key"
  public_key      = tls_private_key.private_key.public_key_openssh
}

resource "local_sensitive_file" "ec_key_file" {
  content         = tls_private_key.private_key.private_key_pem
  filename        = "harjus-ec2-key.pem"
  file_permission = "0400"
}

# end ssh resources


resource "aws_instance" "instance" {

  # Ubuntu 25.04 HVM ebs-ssd-gp3
  ami = "ami-02145888c84f41705"

  instance_type        = "c6in.xlarge"
  key_name             = aws_key_pair.ec_key.key_name
  security_groups      = [aws_security_group.security.name]

  user_data_replace_on_change = true

  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "harjus-instance"
  }
}
