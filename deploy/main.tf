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

  instance_type   = "t3a.small"
  key_name        = aws_key_pair.ec_key.key_name
  security_groups = [aws_security_group.security.name]
  user_data       = <<-EOF
                      #!/bin/bash
                      set -e

                      # required to join ECS
                      echo ECS_CLUSTER=${aws_ecs_cluster.ecs_cluster.name} >> /etc/ecs/ecs.config

                      # begin optimized resolver config
                      dnf install -y nmap bind-utils

                      NUM_PROBES=${var.num_nping_probes}

                      endpoints=( "data-stream.binance.vision:443" "stream.binance.com:443" "data-stream.binance.com:443" )
                      for pair in "$${endpoints[@]}"; do
                        host=$(echo $pair | awk -F: '{print $1}')
                        port=$(echo $pair | awk -F: '{print $2}')

                        best_ip=$(for ip in `dig +short $host`; do
                          avg_rtt=`nping -c "$NUM_PROBES" --tcp -p "$port" "$ip" |grep "Avg rtt" |awk '{print $11}'`
                          echo "$ip $avg_rtt"
                        done|sort -k2 -n | head -n1|awk '{print $1}')

                        # add the best IP to /etc/hosts
                        echo "$best_ip $host" >> /etc/hosts
                      done

                      # end optimized resolver config
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

resource "aws_ecs_task_definition" "ecs_td" {
  family                   = "harjus"
  requires_compatibilities = ["EC2"]
  network_mode             = "host"
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
          name  = "AWS_REGION"
          value = var.aws_region
        },
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

resource "aws_cloudwatch_dashboard" "dashboard" {
  dashboard_name = "harjus"
  dashboard_body = jsonencode({
    "widgets" : [
      {
        "height" : 3,
        "width" : 6,
        "y" : 1,
        "x" : 9,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            [{ "color" : "#2ca02c", "expression" : "RUNNING_SUM(m1)", "id" : "e1", "label" : "Winning", "period" : 86400, "region" : var.aws_region, "stat" : "Sum" }],
            [{ "color" : "#d62728", "expression" : "RUNNING_SUM(m2)", "id" : "e2", "label" : "Losing", "period" : 86400, "region" : var.aws_region, "stat" : "Sum" }],
            ["Harjus", "harjus.trader.trade.winning.count", { "color" : "#2ca02c", "id" : "m1", "region" : var.aws_region, "visible" : false }],
            [".", "harjus.trader.trade.losing.count", { "color" : "#d62728", "id" : "m2", "region" : var.aws_region, "visible" : false }]
          ],
          "period" : 86400,
          "region" : var.aws_region,
          "stacked" : true,
          "stat" : "Sum",
          "title" : "Winning vs Losing trades in 24h",
          "view" : "singleValue"
        }
      },
      {
        "height" : 1,
        "width" : 15,
        "y" : 0,
        "x" : 0,
        "type" : "text",
        "properties" : {
          "background" : "solid",
          "markdown" : "# Business metrics"
        }
      },
      {
        "height" : 1,
        "width" : 9,
        "y" : 0,
        "x" : 15,
        "type" : "text",
        "properties" : {
          "background" : "solid",
          "markdown" : "# Alarms"
        }
      },
      {
        "height" : 5,
        "width" : 24,
        "y" : 8,
        "x" : 0,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            ["Harjus", "vm.memory.total.last_value", { "region" : var.aws_region }],
            [".", "vm.total_run_queue_lengths.cpu.last_value", { "region" : var.aws_region }],
            [".", "vm.total_run_queue_lengths.io.last_value", { "region" : var.aws_region }],
            [".", "vm.total_run_queue_lengths.total.last_value", { "region" : var.aws_region }]
          ],
          "period" : 300,
          "region" : var.aws_region,
          "sparkline" : true,
          "title" : "Erlang VM metrics",
          "view" : "singleValue"
        }
      },
      {
        "height" : 1,
        "width" : 24,
        "y" : 7,
        "x" : 0,
        "type" : "text",
        "properties" : {
          "background" : "solid",
          "markdown" : "# Host, VM metrics"
        }
      },
      {
        "height" : 3,
        "width" : 9,
        "y" : 1,
        "x" : 0,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            [{ "expression" : "RATE(RUNNING_SUM(m1))", "id" : "e1", "label" : "Price updates", "period" : 1, "region" : var.aws_region, "stat" : "Sum" }],
            [{ "expression" : "RATE(RUNNING_SUM(m2))", "id" : "e2", "label" : "Attempted trades", "period" : 1, "region" : var.aws_region, "stat" : "Sum" }],
            [{ "expression" : "RATE(RUNNING_SUM(m3))", "id" : "e3", "label" : "Executions", "period" : 1, "region" : var.aws_region, "stat" : "Sum" }],
            ["Harjus", "harjus.price_streamer.price_update.count", { "id" : "m1", "region" : var.aws_region, "visible" : false }],
            [".", "harjus.trader.trade.attempted.count", { "id" : "m2", "region" : var.aws_region, "visible" : false }],
            [".", "harjus.trader.trade.executed.count", { "id" : "m3", "region" : var.aws_region, "visible" : false }]
          ],
          "period" : 1,
          "region" : var.aws_region,
          "stat" : "Sum",
          "title" : "Events per second",
          "view" : "singleValue",
          "yAxis" : {
            "left" : {
              "max" : 100,
              "min" : 0
            }
          }
        }
      },
      {
        "height" : 3,
        "width" : 24,
        "y" : 13,
        "x" : 0,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            ["AWS/ECS", "CPUUtilization", "ClusterName", "harjus"],
            [".", "MemoryUtilization", ".", "."],
            [".", "CPUReservation", ".", "."],
            [".", "MemoryReservation", ".", "."]
          ],
          "region" : var.aws_region,
          "sparkline" : true,
          "view" : "singleValue"
        }
      },
      {
        "height" : 3,
        "width" : 15,
        "y" : 4,
        "x" : 0,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            [{ "expression" : "RUNNING_SUM(m1)", "id" : "e1", "label" : "BTC", "period" : 1, "stat" : "Sum" }],
            [{ "expression" : "RUNNING_SUM(m2)", "id" : "e2", "label" : "ETH", "period" : 1, "stat" : "Sum" }],
            [{ "expression" : "RUNNING_SUM(m3)", "id" : "e3", "label" : "USDT", "period" : 1, "stat" : "Sum" }],
            ["Harjus", "harjus.trader.trade.report.summary", "asset", "BTC", { "id" : "m1", "visible" : false }],
            ["...", "ETH", { "id" : "m2", "visible" : false }],
            ["...", "USDT", { "id" : "m3", "visible" : false }]
          ],
          "period" : 1,
          "region" : var.aws_region,
          "sparkline" : true,
          "stat" : "Sum",
          "title" : "Balances",
          "view" : "singleValue"
        }
      },
      {
        "type" : "alarm",
        "x" : 15,
        "y" : 1,
        "width" : 9,
        "height" : 6,
        "properties" : {
          "title" : "Alarms",
          "alarms" : [
            aws_cloudwatch_metric_alarm.ecs_instance_filesystem_utilization.arn,
            aws_cloudwatch_metric_alarm.ecs_running_task_count.arn,
            aws_cloudwatch_metric_alarm.ecs_cpu_utilization.arn,
            aws_cloudwatch_metric_alarm.ecs_memory_reservation.arn,
            aws_cloudwatch_metric_alarm.cpu_utilization.arn,
            aws_cloudwatch_metric_alarm.status_check.arn
          ]
        }
      }
    ]
  })


}

# alarms

# EC2 recommended alarms https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Best_Practice_Recommended_Alarms_AWS_Services.html#EC2
resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  alarm_name          = "ec2_cpu_utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  datapoints_to_alarm = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors ec2 cpu utilization"
}

resource "aws_cloudwatch_metric_alarm" "status_check" {
  alarm_name          = "ec2_cpu_utilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Maximum"
  threshold           = 1.0
  alarm_description   = "This alarm helps to monitor both system status checks and instance status checks."
}

# ECS recommended alarms https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Best_Practice_Recommended_Alarms_AWS_Services.html#ECS
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_reservation" {
  alarm_name          = "ecs_cpu_reservation"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  datapoints_to_alarm = 5
  metric_name         = "CPUReservation"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80.0
  alarm_description   = "This alarm helps to monitor cpu reservation of the cluster."
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu_utilization" {
  alarm_name          = "ecs_cpu_utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  datapoints_to_alarm = 5
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80.0
  alarm_description   = "This alarm helps to monitor cpu utilization of the cluster."
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory_reservation" {
  alarm_name          = "ecs_memory_reservation"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  datapoints_to_alarm = 5
  metric_name         = "MemoryReservation"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80.0
  alarm_description   = "This alarm helps to monitor memory reservation of the cluster."
}

# container insights recommended alarms https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Best_Practice_Recommended_Alarms_AWS_Services.html#ECS-ContainerInsights

resource "aws_cloudwatch_metric_alarm" "ecs_instance_filesystem_utilization" {
  alarm_name          = "ecs_instance_filesystem_utilization"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 5
  datapoints_to_alarm = 5
  metric_name         = "RunningTaskCount"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 0.0
  alarm_description   = "This alarm helps detect a low running task count of the ECS service."
}

resource "aws_cloudwatch_metric_alarm" "ecs_running_task_count" {
  alarm_name          = "ecs_runnin_task_count"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  datapoints_to_alarm = 5
  metric_name         = "instance_filesystem_utilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 90.0
  alarm_description   = "This alarm helps you detect a high file system utilization of the ECS cluster."
}
