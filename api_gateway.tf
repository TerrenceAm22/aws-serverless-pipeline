resource "aws_api_gateway_rest_api" "data_api" {
  name        = "ServerlessDataAPI"
  description = "API Gateway for handling data submissions"
}

resource "aws_api_gateway_resource" "submit_data" {
  rest_api_id = aws_api_gateway_rest_api.data_api.id
  parent_id   = aws_api_gateway_rest_api.data_api.root_resource_id
  path_part   = "submitData"
}

resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.data_api.id
  resource_id   = aws_api_gateway_resource.submit_data.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.data_api.id
  resource_id = aws_api_gateway_resource.submit_data.id
  http_method = aws_api_gateway_method.post_method.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri  = aws_lambda_function.data_processor.invoke_arn
}
resource "aws_api_gateway_method" "get_data" {  
  rest_api_id   = aws_api_gateway_rest_api.data_api.id
  resource_id   = aws_api_gateway_resource.get_data.id
  http_method   = "GET"
  authorization = "NONE"
}
resource "aws_api_gateway_method" "list_data" {  
  rest_api_id   = aws_api_gateway_rest_api.data_api.id
  resource_id   = aws_api_gateway_resource.list_data.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_resource" "list_data" {  
  rest_api_id = aws_api_gateway_rest_api.data_api.id
  parent_id   = aws_api_gateway_rest_api.data_api.root_resource_id
  path_part   = "listData"
}
resource "aws_api_gateway_resource" "get_data" {
  rest_api_id = aws_api_gateway_rest_api.data_api.id
  parent_id   = aws_api_gateway_rest_api.data_api.root_resource_id
  path_part   = "getData"
}


resource "aws_api_gateway_deployment" "api_deploy" {
  rest_api_id = aws_api_gateway_rest_api.data_api.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.data_api.body))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_method.post_method,
    aws_api_gateway_method.get_data,
    aws_api_gateway_method.list_data
  ]
}



resource "aws_api_gateway_stage" "prod_stage" {
  deployment_id = aws_api_gateway_deployment.api_deploy.id
  rest_api_id   = aws_api_gateway_rest_api.data_api.id
  stage_name    = "prod"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw_logs.arn
    format          = "$context.requestId $context.path $context.status $context.responseLatency"
  }
}

resource "aws_cloudwatch_log_group" "api_gw_logs" {
  name              = "/aws/apigateway/ServerlessDataAPI"
  retention_in_days = 7
}
