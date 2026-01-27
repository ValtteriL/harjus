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

  # debian-13-amd64-20250814-2204
  ami = "ami-01a89c4a177e76f46"

  instance_type        = "c6in.xlarge"
  key_name             = aws_key_pair.ec_key.key_name
  security_groups      = [aws_security_group.security.name]

  user_data_replace_on_change = true

  availability_zone = var.availability_zone

  tags = {
    Name = "harjus-instance"
  }

}

resource "aws_network_interface" "dpdk_interface" {
  subnet_id         = aws_instance.instance.subnet_id
  security_groups   = [aws_security_group.security.id]
  source_dest_check = false

  attachment {
    instance     = aws_instance.instance.id
    device_index = 1
  }
}

# Elastic IP for the DPDK interface to enable internet access
resource "aws_eip" "dpdk_eip" {
  domain            = "vpc"
  network_interface = aws_network_interface.dpdk_interface.id

  # Ensure the interface is attached before associating EIP
  depends_on = [aws_network_interface.dpdk_interface]

  tags = {
    Name = "harjus-dpdk-eip"
  }
}
