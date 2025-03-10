resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/dataProcessor"
  retention_in_days = 7
}
