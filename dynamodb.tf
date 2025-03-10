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
