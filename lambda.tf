# Description: This file contains the terraform code to create a lambda function.
resource "aws_lambda_function" "data_processor" {
  function_name    = "dataProcessor"
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda_handler.lambda_handler"
  runtime         = "python3.8"

  filename         = "lambda_function.zip"  # ✅ Ensure this is included

  environment {
    variables = {
      DYNAMODB_TABLE   = aws_dynamodb_table.data_table.name
      RATE_LIMIT_TABLE = aws_dynamodb_table.rate_limit_table.name
      EVENT_BUS_NAME   = aws_cloudwatch_event_bus.data_submission_bus.name
      SQS_QUEUE_URL    = aws_sqs_queue.submission_queue.url
    }
  }
}
