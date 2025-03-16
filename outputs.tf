output "api_gateway_url" {
  value = aws_api_gateway_deployment.api_deploy.invoke_url
}

output "lambda_function_arn" {
  value = aws_lambda_function.data_processor.arn
}

# output "lambda_execution_rule_name" {
#   value = aws_cloudwatch_event_rule.lambda_execution_rule.name
# }
