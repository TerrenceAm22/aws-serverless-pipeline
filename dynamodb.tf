resource "aws_dynamodb_table" "data_table" {
  name         = "UserSubmissions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name = "UserSubmissionsTable"
  }
}

resource "aws_dynamodb_table" "rate_limit_table" {
  name         = "UserRateLimit"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user_id"

  attribute {
    name = "user_id"
    type = "S"
  }
}

resource "aws_dynamodb_table" "analytics_table" {
  name         = "AnalyticsData"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "submission_id"

  attribute {
    name = "submission_id"
    type = "S"
  }
}
