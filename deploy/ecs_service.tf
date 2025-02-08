# resource "aws_ecs_task_definition" "qa_task" {
#   family                = var.task_definition_family
#   network_mode          = "awsvpc"
#   requires_compatibilities = ["EC2"]
#   cpu                   = "256"
#   memory                = "512"
#   execution_role_arn    = aws_iam_role.ecs_task_execution_role.arn
#   container_definitions = jsonencode([
#     {
#       name      = var.container_name
#       image     = "${aws_ecr_repository.qa_repository.repository_url}:${var.image_tag}"
#       essential = true
#     }
#   ])
# }

# resource "aws_ecs_service" "qa_service" {
#   name            = var.service_name
#   cluster         = aws_ecs_cluster.qa_cluster.id
#   task_definition = aws_ecs_task_definition.qa_task.arn
#   desired_count   = 1
#   launch_type     = "EC2"
#   network_configuration {
#     subnets         = var.subnets
#     security_groups = var.security_groups
#   }
#   deployment_controller {
#     type = "ECS"
#   }
#   deployment_maximum_percent         = 200
#   deployment_minimum_healthy_percent = 100
# }

# provider "aws" {
#   region  = var.aws_region
#   access_key = var.aws_access_key
#   secret_key = var.aws_secret_key
# }

# resource "aws_cloudwatch_log_group" "ecs_service_log_group" {
#   name              = "/ecs/${var.service_name}"
#   retention_in_days = 7
# }

# resource "aws_cloudwatch_metric_alarm" "prometheus_metrics_alarm" {
#   alarm_name          = "PrometheusMetricsAlarm"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = 1
#   metric_name         = "PrometheusMetrics"
#   namespace           = "AWS/ECS"
#   period              = 60
#   statistic           = "Average"
#   threshold           = 1
#   alarm_description   = "Alarm for Prometheus metrics on port 1337"
#   dimensions = {
#     ClusterName = aws_ecs_cluster.qa_cluster.name
#     ServiceName = aws_ecs_service.qa_service.name
#   }
# }

# resource "aws_cloudwatch_log_metric_filter" "prometheus_metrics_filter" {
#   name           = "PrometheusMetricsFilter"
#   log_group_name = aws_cloudwatch_log_group.ecs_service_log_group.name
#   pattern        = "{ $.port = 1337 }"
#   metric_transformation {
#     name      = "PrometheusMetrics"
#     namespace = "AWS/ECS"
#     value     = "1"
#   }
# }
