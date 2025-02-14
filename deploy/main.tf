terraform {
  # these come from the backend directory
  backend "s3" {
    encrypt        = true
    bucket         = "harjus-terraform-state20250208211637665900000001"
    key            = "path/to/state"
    region         = "eu-north-1"
    dynamodb_table = "terraform-lock"
  }
}

resource "aws_ecr_repository" "ecr_repository" {
  name = "harjus"
}


resource "aws_secretsmanager_secret" "binance_ed25519_api_key" {
  name_prefix = "harjus-binance-api-key"
  description = "Binance API key for FIX API"
}

resource "aws_secretsmanager_secret_version" "binance_ed25519_api_key" {
  secret_id     = aws_secretsmanager_secret.binance_ed25519_api_key.id
  secret_string = var.binance_ed25519_api_key
}

resource "aws_secretsmanager_secret" "binance_ed25519_private_key" {
  name_prefix = "harjus-binance-api-private-key"
  description = "Binance ED25519 private key for FIX API"
}

resource "aws_secretsmanager_secret_version" "binance_ed25519_private_key" {
  secret_id     = aws_secretsmanager_secret.binance_ed25519_private_key.id
  secret_string = var.binance_ed25519_private_key
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

# begin ECS

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "harjus"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_iam_role" "ecsInstanceRole" {
  name               = "ecsInstanceRole"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecsInstanceRole" {
  role       = aws_iam_role.ecsInstanceRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "iam_instance_profile" {
  name = "ecsInstanceProfile"
  role = aws_iam_role.ecsInstanceRole.name
}

resource "aws_instance" "ecs_instance" {

  # Amazon ECS-optimized Amazon Linux 2023 AMI
  # source: https://github.com/aws/amazon-ecs-ami/releases
  # al2023-ami-ecs-hvm-2023.0.20250129-kernel-6.1-x86_64
  # this joins the given ECS cluster automatically at startup
  ami = "ami-029678e4f0fddbf9b"

  instance_type   = "t3a.small"
  key_name        = aws_key_pair.ec_key.key_name
  security_groups = [aws_security_group.security.name]
  user_data       = <<-EOF
                      #!/bin/bash
                      echo ECS_CLUSTER=${aws_ecs_cluster.ecs_cluster.name} >> /etc/ecs/ecs.config
                      EOF

  user_data_replace_on_change = true

  iam_instance_profile = aws_iam_instance_profile.iam_instance_profile.name # required to be able to join ECS

  tags = {
    Name = "harjus-ecs-instance"
  }
}

resource "aws_ecs_task_definition" "ecs_td" {
  family                   = "harjus"
  requires_compatibilities = ["EC2"]
  container_definitions = jsonencode([
    {
      name              = "harjus"
      image             = "${aws_ecr_repository.ecr_repository.repository_url}:${var.image_tag}"
      essential         = true
      startTimeout      = 60
      stopTimeout       = 60
      memoryReservation = 256
      environment = [
        {
          name      = "BINANCE_API_KEY"
          valueFrom = aws_secretsmanager_secret_version.binance_ed25519_api_key.secret_string
        },
        {
          name      = "BINANCE_PRIVATE_KEY"
          valueFrom = aws_secretsmanager_secret_version.binance_ed25519_private_key.secret_string
        },
        {
          name  = "NUMBER_OF_TRADERS"
          value = "${tostring(var.number_of_traders)}"
        },
        {
          name  = "MAX_TRADING_PATH_LENGTH"
          value = "${tostring(var.max_trading_path_length)}"
        },
        {
          name  = "START_SYMBOLS"
          value = var.start_symbols
        },
        {
          name  = "MIN_PROFIT_PERCENTAGE"
          value = "${tostring(var.min_profit_percentage)}"
        },
        {
          name  = "COMMISSION"
          value = "${tostring(var.commission)}"
        },
        {
          name  = "MIN_CAPACITY"
          value = "${tostring(var.min_capacity)}"
        },
        {
          name  = "BINANCE_WEBSOCKET_STREAM_URI"
          value = var.binance_websocket_stream_uri
        },
        {
          name  = "BINANCE_REST_API_URI"
          value = var.binance_rest_api_uri
        },
        {
          name  = "BINANCE_FIX_API_HOSTNAME"
          value = var.binance_fix_api_hostname
        },
        {
          name  = "BINANCE_FIX_API_PORT"
          value = var.binance_fix_api_port
        },
        {
          name  = "BINANCE_MARKET_DATA_API_URI"
          value = var.binance_market_data_api_uri
        },
        {
          name  = "VERBOSITY"
          value = var.verbosity
        },
        {
          name  = "MARKET_DATA_EXCHANGE"
          value = var.market_data_exchange
        },
        {
          name  = "PRICE_STREAMER_EXCHANGE"
          value = var.price_streamer_exchange
        },
        {
          name  = "TRADE_CLIENT_EXCHANGE"
          value = var.trade_client_exchange
        },
        {
          name  = "BALANCE_EXCHANGE"
          value = var.balance_exchange
        }
      ],
      "healthCheck" : {
        "command" : ["CMD-SHELL", "harjus pid"],
        "interval" : 30,
        "timeout" : 2,
        "retries" : 3,
        "startPeriod" : 30
      },
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : "/ecs/harjus",
          "awslogs-region" : var.aws_region,
          "awslogs-stream-prefix" : "ecs"
        }
      }
    }
  ])

}

resource "aws_ecs_service" "ecs_service" {
  name            = "harjus"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_td.arn

  # deploy only one instance of the task, keep at most one running
  desired_count                      = 1
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  launch_type = "EC2"

  deployment_controller {
    type = "ECS"
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  log_configuration {
    log_driver = "awslogs"
    options = {
      awslogs-group         = "/ecs/harjus"
      awslogs-region        = var.aws_region
      awslogs-stream-prefix = "ecs"
    }
  }
}

# end ECS
