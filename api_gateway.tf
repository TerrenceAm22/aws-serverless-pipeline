resource "aws_api_gateway_rest_api" "data_api" {
  name        = "ServerlessDataAPI"
  description = "API Gateway for handling data submissions"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "submit_data" {
  rest_api_id = aws_api_gateway_rest_api.data_api.id
  parent_id   = aws_api_gateway_rest_api.data_api.root_resource_id
  path_part   = "submitData"
}

resource "aws_api_gateway_resource" "get_data" {
  rest_api_id = aws_api_gateway_rest_api.data_api.id
  parent_id   = aws_api_gateway_rest_api.data_api.root_resource_id
  path_part   = "getData"
}

resource "aws_api_gateway_resource" "list_data" {
  rest_api_id = aws_api_gateway_rest_api.data_api.id
  parent_id   = aws_api_gateway_rest_api.data_api.root_resource_id
  path_part   = "listData"
}

resource "aws_api_gateway_method" "post_submit_data" {
  rest_api_id      = aws_api_gateway_rest_api.data_api.id
  resource_id      = aws_api_gateway_resource.submit_data.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true

  lifecycle {
    ignore_changes = [authorization, api_key_required] # ✅ Prevents unnecessary recreation
  }
}

resource "aws_api_gateway_method" "get_list_data" {
  rest_api_id      = aws_api_gateway_rest_api.data_api.id
  resource_id      = aws_api_gateway_resource.list_data.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = true

  lifecycle {
    ignore_changes = [authorization, api_key_required] # ✅ Prevents unnecessary recreation
  }
}


resource "aws_api_gateway_method" "get_data" {
  rest_api_id   = aws_api_gateway_rest_api.data_api.id
  resource_id   = aws_api_gateway_resource.get_data.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration_post" {
  rest_api_id             = aws_api_gateway_rest_api.data_api.id
  resource_id             = aws_api_gateway_resource.submit_data.id
  http_method             = aws_api_gateway_method.post_submit_data.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.data_processor.invoke_arn
}

resource "aws_api_gateway_integration" "lambda_integration_get" {
  rest_api_id             = aws_api_gateway_rest_api.data_api.id
  resource_id             = aws_api_gateway_resource.get_data.id
  http_method             = aws_api_gateway_method.get_data.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.data_processor.invoke_arn
}


resource "aws_api_gateway_integration" "lambda_integration_get_list" {
  rest_api_id             = aws_api_gateway_rest_api.data_api.id
  resource_id             = aws_api_gateway_resource.list_data.id
  http_method             = aws_api_gateway_method.get_list_data.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.data_processor.invoke_arn
}

resource "aws_api_gateway_deployment" "api_deploy" {
  rest_api_id = aws_api_gateway_rest_api.data_api.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.data_api))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod_stage" {
  stage_name    = "prod"
  rest_api_id   = aws_api_gateway_rest_api.data_api.id
  deployment_id = aws_api_gateway_deployment.api_deploy.id

  depends_on = [aws_api_gateway_deployment.api_deploy]
}

resource "aws_api_gateway_usage_plan" "default" {
  name        = "default-usage-plan"
  description = "Usage plan for API key authentication"

  api_stages {
    api_id = aws_api_gateway_rest_api.data_api.id
    stage  = aws_api_gateway_stage.prod_stage.stage_name
  }

  depends_on = [aws_api_gateway_stage.prod_stage]
}

resource "aws_api_gateway_api_key" "client_key" {
  name        = "client-key"
  description = "API Key for secure access"
  enabled     = true
}

resource "aws_api_gateway_usage_plan_key" "client_key_association" {
  key_id        = aws_api_gateway_api_key.client_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.default.id

  depends_on = [aws_api_gateway_usage_plan.default]
}
