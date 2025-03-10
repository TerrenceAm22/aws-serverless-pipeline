terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket" # ✅ Replace with your S3 bucket
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock" # ✅ For state locking
  }
}

provider "aws" {
  region = "us-east-1"
}
