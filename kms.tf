resource "aws_kms_key" "lambda_kms_key" {
  description         = "KMS Key for Lambda environment variable encryption"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "kms-lambda-policy",
    Statement = [
      # ✅ AWS Root User full access
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::571600861898:root"
        },
        Action   = "kms:*",
        Resource = "*"
      },
      # ✅ Allow Lambda execution role to use the key
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::571600861898:role/lambda_execution_role"
        },
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ],
        Resource = "arn:aws:kms:us-east-1:571600861898:key/"
      },
      # ✅ STS-assumed roles (Lambda when running)
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:sts::571600861898:assumed-role/lambda_execution_role/AnalyticsProcessor"
        },
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ],
        Resource = "arn:aws:kms:us-east-1:571600861898:key/3edaaa00-c70f-4c87-b5f3-b3140e83792d"
      }
    ]
  })
}
