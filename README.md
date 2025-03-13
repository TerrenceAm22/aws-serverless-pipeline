
![Lab (1)](https://github.com/user-attachments/assets/9282bf86-2366-4c6d-80a0-57a523cd6e76)










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

Make sure to .zip the file, you can also configure the yml file the github actions to do it during deployment. 

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




Security Aspect.


API Access requires 

Helps retrict access to the API to only authorized clients.
Also helps with usage tracking which clients hit the API the most. Alot of business utlity there. 
Header in this format x-api-key. 


IAM roles are set up in a way for least privilege, which ensures a resource only has the permission to do what it needs to do. Which helps with preventing accidental deletion of data or of modifying data or exposing. 

Also helps meet compliance for company security requirements.


 I am  also automating this deployment everytime I do a push to the repo using github actions. This is setup in the yml file which defines what happens during terraform deplyoments. 

You can specify when to run either on push or pull onto the main branch.\

You set permissions to read and write from the repo.

You name the particular deployment. I have named it Terraform Deployment, which runs on a ubuntu runner. 

Step 1: 

CLones the repo into the runner, it needs access to the terraform and lambda files. 

Step 2:

Installs terraform on the runner.

Step 3:

You are able to add this step if you want to automate the zipping of the lamda function

Step 4:

Ensure proper syntax before deploying. Run "terraform fmt" manually in command line is an option. 

Step 5:

Verify proper AWS credentials, make sure to use proper secrets variables as best practice. You set these secrets in your Github account. 


Step 6:

Terraform Init


Step 7:

Terraform Plan
You can also use terraform plan -out=tfplan which saves the plan, which helps prevent unexpected changes. For example manually modifying a S3 bucket
from the console instead of the terraform deployment. 

Step 8:

Terraform Apply
