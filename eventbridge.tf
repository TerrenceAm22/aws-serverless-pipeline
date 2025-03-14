resource "aws_cloudwatch_event_bus" "data_submission_bus" {
  name = "DataSubmissionBus"
}


# Create EventBridge Rule (Ensure it is on the correct Event Bus)
resource "aws_cloudwatch_event_rule" "new_data_submission_rule" {
  name           = "NewDataSubmissionRule"
  description    = "Trigger SNS on Lambda suucess or failure"
  event_bus_name = aws_cloudwatch_event_bus.data_submission_bus.name

  event_pattern = jsonencode({
    "source" : ["dataProcessor.lambda"],
    "detail-type" : ["Lambda Function Invocation Result - Success", "Lambda Function Invocation Result - Failure"]
    "detail" : {
      "status" : ["SUCCESS", "FAILURE"]
    }
  })
}


resource "aws_sns_topic" "lambda_event_topic" {
  name = "lambda-execution-events"
}

resource "aws_cloudwatch_event_target" "sns_target" {
  rule      = aws_cloudwatch_event_rule.lambda_execution_rule.name
  arn       = aws_sns_topic.lambda_event_topic.arn

  # Ensures the SNS Topic is created before the Event Target
  depends_on = [aws_cloudwatch_event_rule.new_data_submission_rule]
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



# Ensure Rule Exists Before Creating Target
resource "aws_cloudwatch_event_target" "analytics_lambda_target" {
  rule           = aws_cloudwatch_event_rule.new_data_submission_rule.name
  target_id      = "InvokeAnalyticsLambda"
  arn            = aws_lambda_function.analytics_processor.arn
  event_bus_name = aws_cloudwatch_event_bus.data_submission_bus.name # Ensures target is on the correct event bus

  depends_on = [aws_cloudwatch_event_rule.new_data_submission_rule] # Ensures rule exists before target is created
}

# Allow EventBridge to Invoke Analytics Lambda
resource "aws_lambda_permission" "eventbridge_permission" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.analytics_processor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.new_data_submission_rule.arn
}

