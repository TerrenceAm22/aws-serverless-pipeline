# ✅ CloudWatch Alarm for Lambda Errors
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "LambdaDataProcessorErrors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Triggers when Lambda function has 1 or more errors in 60 seconds"
  alarm_actions       = [aws_sns_topic.lambda_alerts.arn] # SNS Topic for notifications

  dimensions = {
    FunctionName = aws_lambda_function.data_processor.function_name
  }
}

# CloudWatch Log Group with Retention Policy (7 Days)
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.data_processor.function_name}"
  retention_in_days = 7 # Keeps logs for 7 days before deletion
}

# SNS Topic for CloudWatch Alarms
resource "aws_sns_topic" "lambda_alerts" {
  name = "LambdaAlertsTopic"
}

#  Subscribe an Email for Notifications
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.lambda_alerts.arn
  protocol  = "email"
  endpoint  = "terrence.malone@ahead.com"
}
