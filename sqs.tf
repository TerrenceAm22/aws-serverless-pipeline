# Create an SQS Queue for Analytics Processing
resource "aws_sqs_queue" "analytics_queue" {
  name = "AnalyticsProcessingQueue"
}

resource "aws_sqs_queue" "sns_sqs_queue" {
  name = "SNSToSQSQueue"
}



resource "aws_sqs_queue" "submission_queue" {
  name                       = "DataSubmissionQueue"
  delay_seconds              = 0
  visibility_timeout_seconds = 30
}

resource "aws_sns_topic_subscription" "sqs_subscription" {
  topic_arn = aws_sns_topic.lambda_event_topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.sns_sqs_queue.arn
}


resource "aws_sqs_queue_policy" "sns_sqs_policy" {
  queue_url = aws_sqs_queue.submission_queue.url

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "sns.amazonaws.com"
        },
        Action = "SQS:SendMessage",
        Resource = aws_sqs_queue.submission_queue.arn,
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.lambda_event_topic.arn
          }
        }
      }
    ]
  })
}


