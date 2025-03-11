# ✅ Create an S3 Bucket for Analytics Data
resource "aws_s3_bucket" "analytics_data" {
  bucket = "analytics-data-bucket-${var.environment}"
}

# ✅ Apply an S3 Bucket Policy to Control Access
resource "aws_s3_bucket_policy" "analytics_bucket_policy" {
  bucket = aws_s3_bucket.analytics_data.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = ["s3:GetObject", "s3:PutObject"],
        Resource  = "${aws_s3_bucket.analytics_data.arn}/*"
      }
    ]
  })
}

# ✅ Enable S3 Bucket Versioning 
resource "aws_s3_bucket_versioning" "analytics_versioning" {
  bucket = aws_s3_bucket.analytics_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ✅ Enable Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "analytics_encryption" {
  bucket = aws_s3_bucket.analytics_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Set Lifecycle Policy to Delete Old Data After 30 days
resource "aws_s3_bucket_lifecycle_configuration" "analytics_lifecycle" {
  bucket = aws_s3_bucket.analytics_data.id

  rule {
    id     = "delete-old-logs"
    status = "Enabled"

    expiration {
      days = 30  
    }
  }
}
