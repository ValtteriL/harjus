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
  name = "harjus-ecr-repository"
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

# begin ECS

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "harjus"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_autoscaling_group" "ecs_asg" {
  name_prefix        = "harjus-asg"
  max_size           = 1
  min_size           = 1
  desired_capacity   = 1
  availability_zones = ["${var.aws_region}a"]
  launch_template {
    id      = aws_launch_template.ecs_lt.id
    version = "$Latest"
  }
}

resource "aws_launch_template" "ecs_lt" {
  name_prefix = "harjus-ecs-lt"
  # Amazon ECS-optimized Amazon Linux 2023 AMI
  # source: https://github.com/aws/amazon-ecs-ami/releases
  # al2023-ami-ecs-hvm-2023.0.20250129-kernel-6.1-x86_64
  image_id      = "ami-029678e4f0fddbf9b"
  instance_type = "t3a.small"
}

resource "aws_ecs_capacity_provider" "ecs_cap_provider" {
  name = "harjus-cap-provider"
  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs_asg.arn
    managed_scaling {
      status = "ENABLED"
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "ecs_cluster_capacity_providers" {
  cluster_name       = aws_ecs_cluster.ecs_cluster.name
  capacity_providers = [aws_ecs_capacity_provider.ecs_cap_provider.name]
}

resource "aws_ecs_task_definition" "ecs_td" {
  family = "harjus"
  container_definitions = jsonencode([
    {
      name      = "harjus"
      image     = "${aws_ecr_repository.ecr_repository.repository_url}:${var.image_tag}"
      essential = true
      secrets = [
        {
          name      = "BINANCE_API_KEY"
          valueFrom = aws_secretsmanager_secret.binance_ed25519_api_key.arn
        },
        {
          name      = "BINANCE_PRIVATE_KEY"
          valueFrom = aws_secretsmanager_secret.binance_ed25519_private_key.arn
        }
      ]
      environment = [
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
        }
      ]
    }
  ])

}

# end ECS

