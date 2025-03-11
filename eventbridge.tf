# ✅ Create EventBridge Event Bus
resource "aws_cloudwatch_event_bus" "data_submission_bus" {
  name = "DataSubmissionBus"
}

# ✅ Create EventBridge Rule (Ensure it is on the correct Event Bus)
resource "aws_cloudwatch_event_rule" "new_data_submission_rule" {
  name           = "NewDataSubmissionRule"
  description    = "Trigger analytics Lambda when new data is submitted"
  event_bus_name = aws_cloudwatch_event_bus.data_submission_bus.name # ✅ Ensures the rule is associated with the correct event bus

  event_pattern = jsonencode({
    "source" : ["dataProcessor.lambda"],
    "detail-type" : ["NewDataSubmission"]
  })
}

# ✅ Ensure Rule Exists Before Creating Target
resource "aws_cloudwatch_event_target" "analytics_lambda_target" {
  rule           = aws_cloudwatch_event_rule.new_data_submission_rule.name
  target_id      = "InvokeAnalyticsLambda"
  arn            = aws_lambda_function.analytics_processor.arn
  event_bus_name = aws_cloudwatch_event_bus.data_submission_bus.name # ✅ Ensures target is on the correct event bus

  depends_on = [aws_cloudwatch_event_rule.new_data_submission_rule] # ✅ Ensures rule exists before target is created
}

# ✅ Allow EventBridge to Invoke Analytics Lambda
resource "aws_lambda_permission" "eventbridge_permission" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.analytics_processor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.new_data_submission_rule.arn
}

