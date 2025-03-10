resource "aws_cloudwatch_event_rule" "data_submission_rule" {
  name        = "DataSubmissionRule"
  description = "Trigger event when data is submitted"
  event_pattern = jsonencode({
    source      = ["aws.lambda"],
    detail-type = ["DataSubmission"]
  })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule = aws_cloudwatch_event_rule.data_submission_rule.name
  arn  = aws_lambda_function.data_processor.arn
}


resource "aws_cloudwatch_event_bus" "data_submission_bus" {
  name = "DataSubmissionBus"
}
