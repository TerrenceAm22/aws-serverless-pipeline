# Create an EventBridge Rule to Trigger Analytics Lambda
resource "aws_cloudwatch_event_rule" "new_data_submission_rule" {
  name        = "NewDataSubmissionRule"
  description = "Trigger analytics Lambda when new data is submitted"
  event_bus_name = aws_cloudwatch_event_bus.data_submission_bus.name

  event_pattern = jsonencode({
    "source" : ["dataProcessor.lambda"],
    "detail-type" : ["NewDataSubmission"]
  })
}

#Set EventBridge Target to Invoke Analytics Lambda
resource "aws_cloudwatch_event_target" "analytics_lambda_target" {
  rule      = aws_cloudwatch_event_rule.new_data_submission_rule.name
  target_id = "InvokeAnalyticsLambda"
  arn       = aws_lambda_function.analytics_processor.arn
}
