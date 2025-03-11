data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "analytics_data" {
  bucket = "analytics-data-bucket-${data.aws_caller_identity.current.account_id}-${var.environment}"
}


# ✅ Update S3 Bucket Policy to Allow Access Only to Your Account
resource "aws_s3_bucket_policy" "analytics_bucket_policy" {
  bucket = aws_s3_bucket.analytics_data.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Principal = {
          "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = ["s3:GetObject", "s3:PutObject"],
        Resource = "${aws_s3_bucket.analytics_data.arn}/*"
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

# ✅ S3 Lifecycle Policy: Delete "logs/" objects after 90 days
resource "aws_s3_bucket_lifecycle_configuration" "analytics_lifecycle" {
  bucket = aws_s3_bucket.analytics_data.id

  rule {
    id     = "delete-old-logs"
    status = "Enabled"

    filter {
      prefix = "logs/" # ✅ Apply the rule only to objects inside the "logs/" folder
    }

    expiration {
      days = 90 # ✅ Delete logs after 90 days
    }
  }
}

