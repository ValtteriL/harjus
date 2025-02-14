resource "aws_cloudwatch_log_group" "harjus_service_log_group" {
  name              = "/ecs/harjus"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_metric_filter" "harjus_metrics_filter" {
  name           = "HarjusMetricsFilter"
  log_group_name = aws_cloudwatch_log_group.harjus_service_log_group.name
  pattern        = "{ $.port = 1337 }"
  metric_transformation {
    name      = "HarjusMetrics"
    namespace = "AWS/ECS"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_group" "prometheus_metrics_log_group" {
  name              = "/ecs/prometheus_metrics"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_stream" "prometheus_metrics_log_stream" {
  name              = "prometheus_metrics_stream"
  log_group_name    = aws_cloudwatch_log_group.prometheus_metrics_log_group.name
}
