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

resource "aws_cloudwatch_metric_alarm" "harjus_metrics_alarm" {
  alarm_name          = "HarjusMetricsAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HarjusMetrics"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "Alarm for Harjus metrics on port 1337"
  dimensions = {
    ClusterName = aws_ecs_cluster.ecs_cluster.name
    ServiceName = aws_ecs_service.ecs_service.name
  }
}
