resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy_attachment" "lambda_dynamodb_attach" {
  name       = "lambda-dynamodb-policy-attach"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_policy" "lambda_dynamodb_policy" {
  name        = "lambda_dynamodb_policy"
  description = "IAM policy for Lambda to access DynamoDB"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Scan"
        ],
        Effect   = "Allow",
        Resource = aws_dynamodb_table.data_table.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_attach" {
  policy_arn = aws_iam_policy.lambda_dynamodb_policy.arn
  role       = aws_iam_role.lambda_role.name
}


resource "aws_iam_policy" "lambda_eventbridge_policy" {
  name        = "LambdaEventBridgePolicy"
  description = "IAM policy to allow Lambda to publish events to EventBridge"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "events:PutEvents",
        Resource = aws_cloudwatch_event_bus.data_submission_bus.arn
      }
    ]
  })
}

# Attaching the new policy to the Lambda execution role
resource "aws_iam_role_policy_attachment" "lambda_eventbridge_attach" {
  policy_arn = aws_iam_policy.lambda_eventbridge_policy.arn
  role       = aws_iam_role.lambda_role.name
}


resource "aws_iam_policy" "lambda_sqs_policy" {
  name        = "LambdaSQSPolicy"
  description = "IAM policy to allow Lambda to send messages to SQS"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "sqs:SendMessage",
        Resource = aws_sqs_queue.submission_queue.arn
      }
    ]
  })
}

# Attach IAM policy to Lambda execution role
resource "aws_iam_role_policy_attachment" "lambda_sqs_attach" {
  policy_arn = aws_iam_policy.lambda_sqs_policy.arn
  role       = aws_iam_role.lambda_role.name
}
