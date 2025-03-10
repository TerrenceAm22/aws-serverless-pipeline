resource "aws_sqs_queue" "submission_queue" {
  name                       = "DataSubmissionQueue"
  delay_seconds              = 0
  visibility_timeout_seconds = 30
}
