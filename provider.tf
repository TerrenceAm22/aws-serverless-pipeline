terraform {
  backend "s3" {
    bucket         = "your-terraform-states-bucket"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"
  }
}

provider "aws" {
  region = "us-east-1"
}




# The  terraform  block is used to configure the backend. The  backend  block specifies the S3 bucket where the state file will be stored. The  dynamodb_table  attribute is used for state locking. 
# The  provider "aws"  block is used to configure the AWS provider. The  region  attribute specifies the region where the resources will be created. 
# Step 3: Create the Lambda Function 
# Create a new directory called  lambda  in the root of the project. Inside the  lambda  directory, create a new file called  main.py  and add the following code: