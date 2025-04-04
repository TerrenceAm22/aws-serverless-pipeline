# ✅ Define the Lambda Execution Role
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  lifecycle {
    ignore_changes = [name]
  }
}


# Attach DynamoDB Permissions to Lambda
resource "aws_iam_policy" "lambda_dynamodb_policy" {
  name        = "lambda_dynamodb_policy"
  description = "IAM policy for Lambda to access DynamoDB"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Scan"
        ],
        Resource = aws_dynamodb_table.data_table.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_attach" {
  policy_arn = aws_iam_policy.lambda_dynamodb_policy.arn
  role       = aws_iam_role.lambda_execution_role.name # ✅ FIXED
}

# Allow Lambda to Publish Events to EventBridge

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


resource "aws_iam_role_policy_attachment" "lambda_eventbridge_attach" {
  policy_arn = aws_iam_policy.lambda_eventbridge_policy.arn
  role       = aws_iam_role.lambda_execution_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_attach" {
  policy_arn = aws_iam_policy.lambda_sqs_policy.arn
  role       = aws_iam_role.lambda_execution_role.name
}


resource "aws_iam_role_policy_attachment" "lambda_s3_attach" {
  policy_arn = aws_iam_policy.lambda_s3_policy.arn
  role       = aws_iam_role.lambda_execution_role.name
}


# Allow Lambda to Write to S3
resource "aws_iam_policy" "lambda_s3_policy" {
  name        = "LambdaS3Policy"
  description = "Allow Lambda to write to S3"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.analytics_data.arn,
          "${aws_s3_bucket.analytics_data.arn}/*",
          "arn:aws:s3:::analytics-data-bucket-571600861898/analytics/*"
        ]
      }
    ]
  })
}

# IAM Policy for Lambda to Send Messages to SQS
resource "aws_iam_policy" "lambda_sqs_policy" {
  name        = "LambdaSQSPolicy"
  description = "IAM policy to allow Lambda to send messages to SQS"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sqs:SendMessage",
          "sqs:GetQueueUrl",
          "sqs:GetQueueAttributes"
        ],
        Resource = aws_sqs_queue.submission_queue.arn
      }
    ]
  })
}
resource "aws_iam_policy" "lambda_kms_policy" {
  name        = "LambdaKMSPolicy"
  description = "Allow Lambda to decrypt environment variables using KMS"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ],
        Resource = "arn:aws:kms:us-east-1:571600861898:key/3edaaa00-c70f-4c87-b5f3-b3140e83792d"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_kms_attach" {
  policy_arn = aws_iam_policy.lambda_kms_policy.arn
  role       = aws_iam_role.lambda_execution_role.name
}


resource "aws_iam_role" "sns_delivery_logging_role" {
  name = "sns-delivery-logging-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "sns.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "sns_logging_policy" {
  name = "sns-logging-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "sns_logging_attach" {
  role       = aws_iam_role.sns_delivery_logging_role.name
  policy_arn = aws_iam_policy.sns_logging_policy.arn
}


resource "aws_iam_policy" "lambda_sns_publish_policy" {
  name        = "LambdaSNSPublishPolicy"
  description = "Allow Lambda to publish to SNS topic"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement : [
      {
        Effect = "Allow",
        Action = [
          "sns:Publish"
        ],
        Resource = "arn:aws:sns:us-east-1:571600861898:submission-notification-topic"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_sns_publish_attach" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_sns_publish_policy.arn
}
