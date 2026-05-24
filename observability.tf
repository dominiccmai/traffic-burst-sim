# Log group for the app container
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = var.project_name

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "ALB Request Count"
          region = "us-east-1"
          metrics = [["AWS/ApplicationELB", "RequestCount",
            "LoadBalancer", aws_lb.main.arn_suffix,
          { stat = "Sum", period = 60 }]]
          view = "timeSeries"
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "ALB Target Response Time (p95)"
          region = "us-east-1"
          metrics = [["AWS/ApplicationELB", "TargetResponseTime",
            "LoadBalancer", aws_lb.main.arn_suffix,
          { stat = "p95", period = 60 }]]
          view = "timeSeries"
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "ALB Healthy Host Count"
          region = "us-east-1"
          metrics = [["AWS/ApplicationELB", "HealthyHostCount",
            "TargetGroup", aws_lb_target_group.app.arn_suffix,
            "LoadBalancer", aws_lb.main.arn_suffix,
          { stat = "Minimum", period = 60 }]]
          view = "timeSeries"
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "ECS Running Task Count"
          region = "us-east-1"
          metrics = [["ECS/ContainerInsights", "RunningTaskCount",
            "ClusterName", aws_ecs_cluster.main.name,
            "ServiceName", aws_ecs_service.app.name,
          { stat = "Average", period = 60 }]]
          view = "timeSeries"
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "ECS CPU Utilization"
          region = "us-east-1"
          metrics = [["AWS/ECS", "CPUUtilization",
            "ClusterName", aws_ecs_cluster.main.name,
            "ServiceName", aws_ecs_service.app.name,
          { stat = "Average", period = 60 }]]
          view = "timeSeries"
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "ECS Memory Utilization"
          region = "us-east-1"
          metrics = [["AWS/ECS", "MemoryUtilization",
            "ClusterName", aws_ecs_cluster.main.name,
            "ServiceName", aws_ecs_service.app.name,
          { stat = "Average", period = 60 }]]
          view = "timeSeries"
        }
      },
    ]
  })
}

# Fires if any task fails its /health check.
resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "${var.project_name}-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "At least one ALB target is failing health checks"

  dimensions = {
    TargetGroup  = aws_lb_target_group.app.arn_suffix
    LoadBalancer = aws_lb.main.arn_suffix
  }
}
