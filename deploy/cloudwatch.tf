# resource "aws_cloudwatch_log_group" "ecs_service_log_group" {
#   name              = "/ecs/${var.service_name}"
#   retention_in_days = 7
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
