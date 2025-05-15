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

resource "aws_secretsmanager_secret" "binance_ed25519_seed" {
  name_prefix = "harjus-binance-api-private-key"
  description = "Binance ED25519 private key for FIX API"
}

resource "aws_secretsmanager_secret_version" "binance_ed25519_seed" {
  secret_id     = aws_secretsmanager_secret.binance_ed25519_seed.id
  secret_string = var.binance_ed25519_seed
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

resource "aws_iam_role_policy_attachment" "ecsInstanceRole_cloudwatch" {
  role       = aws_iam_role.ecsInstanceRole.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
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

  instance_type   = "c5.large"
  key_name        = aws_key_pair.ec_key.key_name
  security_groups = [aws_security_group.security.name]
  user_data       = <<-EOF
                      #!/bin/bash
                      set -e

                      # required to join ECS
                      echo ECS_CLUSTER=${aws_ecs_cluster.ecs_cluster.name} >> /etc/ecs/ecs.config
                      EOF

  user_data_replace_on_change = true

  iam_instance_profile = aws_iam_instance_profile.iam_instance_profile.name # required to be able to join ECS

  tags = {
    Name = "harjus-ecs-instance"
  }
}

resource "aws_cloudwatch_log_group" "log_group" {
  name_prefix       = "harjus-ecs-logs"
  retention_in_days = 7
}

resource "aws_iam_role" "task_exec_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "task_exec_role" {
  role       = aws_iam_role.task_exec_role.name
  policy_arn = aws_iam_policy.task_exec_role_policy.arn
}

resource "aws_iam_policy" "task_exec_role_policy" {
  name = "policy-618033"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kms:Decrypt",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "ecr:GetAuthorizationToken",

        ]
        Effect = "Allow"
        Resource = [
          aws_secretsmanager_secret.binance_ed25519_api_key.arn,
          aws_secretsmanager_secret.binance_ed25519_seed.arn,
        ]
      },
      {
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchCheckLayerAvailability"
        ]
        Effect   = "Allow"
        Resource = ["*"]
      },
      {
        Effect = "Allow",
        Action = [
          "events:PutRule",
          "events:PutTargets",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = ["*"]
      },
      {
        Effect = "Allow",
        Action = [
          "events:DescribeRule",
          "events:ListTargetsByRule",
          "logs:DescribeLogGroups"
        ],
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_ecs_task_definition" "ecs_td" {
  family                   = "harjus"
  requires_compatibilities = ["EC2"]
  network_mode             = "host"
  execution_role_arn       = aws_iam_role.task_exec_role.arn
  container_definitions = jsonencode([
    {
      name              = "harjus"
      image             = "${aws_ecr_repository.ecr_repository.repository_url}:${var.image_tag}"
      essential         = true
      startTimeout      = 60
      stopTimeout       = 60
      memoryReservation = 1024
      environment = [
        {
          name  = "AWS_REGION"
          value = var.aws_region
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
          name  = "BLACKLISTED_START_SYMBOLS"
          value = var.blacklisted_start_symbols
        },
        {
          name  = "COMMISSION"
          value = "${tostring(var.commission)}"
        },
        {
          name  = "BINANCE_REST_API_URI"
          value = var.binance_rest_api_uri
        },
        {
          name  = "BINANCE_FIX_API_HOSTNAME_MARKETDATA"
          value = var.binance_fix_api_hostname_marketdata
        },
        {
          name  = "BINANCE_FIX_API_PORT_MARKETDATA"
          value = "${tostring(var.binance_fix_api_port_marketdata)}"
        },
        {
          name  = "BINANCE_FIX_API_HOSTNAME_ORDERENTRY"
          value = var.binance_fix_api_hostname_orderentry
        },
        {
          name  = "BINANCE_FIX_API_PORT_ORDERENTRY"
          value = "${tostring(var.binance_fix_api_port_orderentry)}"
        },
        {
          name  = "LOG_LEVEL"
          value = "${tostring(var.log_level)}"
        },
      ],
      secrets : [
        {
          name      = "BINANCE_ED25519_API_KEY",
          valueFrom = aws_secretsmanager_secret_version.binance_ed25519_api_key.arn
        },
        {
          name      = "BINANCE_ED25519_SEED"
          valueFrom = aws_secretsmanager_secret_version.binance_ed25519_seed.arn
        }
      ],
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : aws_cloudwatch_log_group.log_group.name,
          "awslogs-region" : var.aws_region,
          "awslogs-stream-prefix" : "harjus",
          "mode" : "non-blocking"
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
}

# end ECS
