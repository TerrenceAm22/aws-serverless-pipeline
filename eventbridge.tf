resource "aws_cloudwatch_event_bus" "data_submission_bus" {
  name = "DataSubmissionBus"
}

resource "aws_cloudwatch_event_rule" "new_data_submission_rule" {
  name           = "NewDataSubmissionRule"
  description    = "Triggers on new data submission to EventBridge"
  event_bus_name = aws_cloudwatch_event_bus.data_submission_bus.name

  event_pattern = jsonencode({
    source        = ["aws.lambda"]
    "detail-type" = ["Lambda Function Invocation Result - Success or Failure"]
  })
}


resource "aws_sns_topic" "lambda_event_topic" {
  name = "lambda-execution-events"
}

resource "aws_iam_policy" "eventbridge_sns_policy" {
  name        = "EventBridgeSNSPublishPolicy"
  description = "Allows EventBridge to publish messages to SNS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow",
        Action   = "sns:Publish",
        Resource = aws_sns_topic.lambda_event_topic.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eventbridge_sns_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.eventbridge_sns_policy.arn
}

# Creating an SNS Topic for Submission Notifications
resource "aws_sns_topic" "submission_notifications" {
  name = "submission-notification-topic"

  delivery_policy = jsonencode({
    http = {
      defaultHealthyRetryPolicy = {
        minDelayTarget     = 20,
        maxDelayTarget     = 20,
        numRetries         = 3,
        numNoDelayRetries  = 0,
        numMinDelayRetries = 0,
        numMaxDelayRetries = 0,
        backoffFunction    = "linear"
      },
      disableSubscriptionOverrides = false
    }
  })
}


resource "aws_cloudwatch_event_target" "sns_notification_target" {
  rule           = aws_cloudwatch_event_rule.new_data_submission_rule.name
  target_id      = "NotifyViaSNS"
  arn            = aws_sns_topic.submission_notifications.arn
  event_bus_name = aws_cloudwatch_event_bus.data_submission_bus.name

  depends_on = [
    aws_cloudwatch_event_rule.new_data_submission_rule
  ]
}



resource "aws_sns_topic_subscription" "email_subscriber" {
  topic_arn = aws_sns_topic.submission_notifications.arn
  protocol  = "email"
  endpoint  = "tamalone1997@gmail.com"
}

# CloudWatch Alarm: SNS Delivery Failure
resource "aws_cloudwatch_metric_alarm" "sns_delivery_failure_alarm" {
  alarm_name          = "SNSDeliveryFailureAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "NumberOfNotificationsFailed"
  namespace           = "AWS/SNS"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Triggers when SNS fails to deliver messages"
  alarm_actions       = [aws_sns_topic.lambda_alerts.arn]

  dimensions = {
    TopicName = aws_sns_topic.submission_notifications.name
  }
}

# Optional: CloudWatch Alarm for High Successful Delivery Rate
resource "aws_cloudwatch_metric_alarm" "sns_delivery_success_alarm" {
  alarm_name          = "SNSDeliverySuccessSpike"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "NumberOfNotificationsDelivered"
  namespace           = "AWS/SNS"
  period              = 300
  statistic           = "Sum"
  threshold           = 0 # Adjust based on traffic
  alarm_description   = "High volume of SNS message deliveries"
  alarm_actions       = [aws_sns_topic.lambda_alerts.arn]

  dimensions = {
    TopicName = aws_sns_topic.submission_notifications.name
  }
}
