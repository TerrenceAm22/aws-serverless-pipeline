Step by Step Process on setting up a terraform deployment in serverless architecture

STEP 1:
Setting up download of terraform

1. brew tap hashicorp/tap
2. brew install hashicorp/tap/terraform

STEP 2:
Cloud Account set up. This is project deployed with AWS

Step 1: Setup AWS CLI https://docs.aws.amazon.com/streams/latest/dev/setup-awscli.html

In the CLI/Terminal

1. AWS configure - verify installation before
2. Sign in and verify access-key/secret key/region

STEP 3:
Configuring provider.tf file.
Which specifies which cloud provider were using. "AWS"

State locking prevents numerous users from changing the file at the same time using dynamodb
Store terrafrom state in S3 securely.

terraform {
  backend "s3" {
    bucket         = "your-terraform-states-bucket" # S3 bucket where the statefile is stored
    key            = "terraform.tfstate" # Defines the S3 object path in the bucket
    region         = "us-east-1" # Region where the bucket is located
    dynamodb_table = "terraform-lock" # Lock the state file, preventing modification at the same time
  }
}

provider "aws" {
  region = "us-east-1"
}

Running the command  "Terraform Init" :

Sets up the backend specified in the provider.tf file.
Automitically creates the necessary local files and directories. 
Downloads the cloud provider plug in this case AWS.

First command to set up terraform. 

Terraform Plan.
 
Analyzes the current state of the terraform configuration. In this case uses the S3 file in the bucket. 
Compares the current state and the new state for any changes. 

You will then see an output of any changes of resources if they are created, modified, or if any were destroyed. 

Able to review any changes before actually deploying. 


Terraform Apply 

Applies what the command "Terraform Plan" outputted, and deploys any resources that were specified. It creates everything that are specified in the .tf files.

Will be to manually approve the plan by default. Run Terraform Apply -auto-approve to confirm with execution automatically.



Verify Resources created in AWS console. 


Resources created should be: 

1. API Gateway
2. DynamoDB
3. Lambda Function
4. IAM policies configured for each resource. 
5. KMS associated with API, for security. 


Testing API Gateway, with the following endpoints. 

a.	POST /submitData: Accepts user data submissions.
b.	GET /data?id={id} : Retrieves a specific data entry by its ID.
c.	GET /data : return all data

Testing Lambda Function that inserts data
Checks for existing ID before inserting
Check for blacklisted Keywords and rejects submission if they are included
Adds metadata, submission time, stores info in DynamoDB

DynamoDB Table UserSubmission Config

Billing uses pay per request based on read/write permissions
Id as the primary key
Adds a tag

Rate limit table

Uses same billing mode. 
user_id as the primary key

Tracks API usage,
Requests counts per user
Last timestamp see rate limit function in lambda 


Optional updates can include PITR for backup purposes. 
