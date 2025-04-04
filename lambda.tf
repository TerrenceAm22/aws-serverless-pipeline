# Data Processor Lambda Function
resource "aws_lambda_function" "data_processor" {
  function_name = "dataProcessor"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "lambda_handler.lambda_handler"
  runtime       = "python3.8"

  filename         = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")

  environment {
    variables = {
      DYNAMODB_TABLE   = aws_dynamodb_table.data_table.name
      RATE_LIMIT_TABLE = aws_dynamodb_table.rate_limit_table.name
      EVENT_BUS_NAME   = aws_cloudwatch_event_bus.data_submission_bus.name
      SQS_QUEUE_URL    = aws_sqs_queue.submission_queue.url
      SNS_TOPIC_ARN    = aws_sns_topic.submission_notifications.arn #
    }
  }
}


# Create Analytics Lambda Function
resource "aws_lambda_function" "analytics_processor" {
  function_name = "AnalyticsProcessor"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "analytics_handler.lambda_handler"
  runtime       = "python3.8"

  filename         = "analytics_function.zip"
  source_code_hash = filebase64sha256("analytics_function.zip")

  environment {
    variables = {
      ANALYTICS_BUCKET = aws_s3_bucket.analytics_data.id
      ANALYTICS_TABLE  = aws_dynamodb_table.analytics_table.name
    }
  }
}


# Allow SQS to Trigger Analytics Lambda
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.analytics_queue.arn
  function_name    = aws_lambda_function.analytics_processor.arn
  batch_size       = 10
}
