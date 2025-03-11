
# **🚀 Serverless Project Documentation**

## **🔹 Overview**
This project is a **fully serverless** application built using **AWS Lambda, API Gateway, DynamoDB, SQS, EventBridge, and S3**, with **Terraform** for infrastructure as code (IaC). The system processes data submissions, validates requests, enforces rate limits, stores data in DynamoDB, and publishes events to EventBridge and SQS for analytics processing.

---

## **📌 Step 1: Designing the Serverless Architecture**
We designed a **scalable, event-driven serverless architecture** using:
✅ **API Gateway** - Exposes RESTful endpoints  
✅ **AWS Lambda** - Handles data validation & processing  
✅ **DynamoDB** - Stores submitted data  
✅ **SQS** - Queues messages for async processing  
✅ **EventBridge** - Publishes events to trigger analytics workflows  
✅ **S3** - Stores processed analytics data  
✅ **CloudWatch** - Monitors logs and triggers alerts  
✅ **IAM Roles** - Controls permissions for AWS services  

---

## **📌 Step 2: Setting Up Terraform for Infrastructure as Code (IaC)**
We used **Terraform** to manage AWS resources.

1️⃣ **Configured `provider.tf`** with the AWS provider  
2️⃣ **Enabled S3 backend** for Terraform state storage  
3️⃣ **Created IAM roles & permissions** for Lambda and API Gateway  
4️⃣ **Set up API Gateway resources, methods, and integrations**  
5️⃣ **Deployed Lambda functions (`dataProcessor`, `analyticsProcessor`)**  
6️⃣ **Created DynamoDB tables for data storage & rate limiting**  
7️⃣ **Configured EventBridge rules & SQS for event-driven processing**  
8️⃣ **Implemented CloudWatch logging and monitoring**  

✅ **Deployed Terraform with:**
```sh
terraform init
terraform apply
```

---

## **📌 Step 3: Building Lambda Functions**
### **🔹 `dataProcessor` Lambda**
This function:
✔ **Validates incoming requests** (Required fields, rate limits, prohibited words)  
✔ **Stores valid submissions in DynamoDB**  
✔ **Publishes events to EventBridge**  
✔ **Sends messages to SQS for downstream processing**  

### **🔹 `analyticsProcessor` Lambda**
This function:
✔ **Receives SQS messages**  
✔ **Processes and extracts analytics data**  
✔ **Stores processed analytics data in an S3 bucket**  

✅ **Uploaded Lambda functions via CLI:**
```sh
zip -r lambda_function.zip lambda_function.py
aws lambda update-function-code --function-name dataProcessor --zip-file fileb://lambda_function.zip
```

---

## **📌 Step 4: Implementing API Gateway for HTTP Requests**
### **🔹 API Endpoints**
- `POST /submitData` → Submits new data  
- `GET /getData?id={id}` → Retrieves a specific data entry  
- `GET /getData?ids={id1,id2}` → Retrieves multiple entries  
- `GET /listData` → Lists all stored data (Later removed)  

### **🔹 API Key Authentication**
To secure endpoints, we **enabled API Key authentication** and **created a usage plan** to limit API requests.

✅ **Deployed API Gateway via Terraform**

---

## **📌 Step 5: Testing API Gateway & Lambda in Postman**
We tested API Gateway endpoints using **Postman** and **curl**.

✅ **Testing `POST /submitData`**
```sh
curl -X POST "https://your-api-id.execute-api.us-east-1.amazonaws.com/prod/submitData" \
-H "Content-Type: application/json" \
-H "x-api-key: your-api-key-here" \
-d '{
  "id": "test-001",
  "data": "Hello Serverless",
  "user": "Alice"
}'
```

✅ **Testing `GET /getData?id=test-001`**
```sh
curl -X GET "https://your-api-id.execute-api.us-east-1.amazonaws.com/prod/getData?id=test-001" \
-H "x-api-key: your-api-key-here"
```

---

## **📌 Step 6: Implementing Bulk Insert in API & Lambda**
🔹 We **updated the `dataProcessor` Lambda** to support **bulk data insertion** using an array of JSON objects.

✅ **Testing Bulk Submission**
```sh
curl -X POST "https://your-api-id.execute-api.us-east-1.amazonaws.com/prod/submitData" \
-H "Content-Type: application/json" \
-H "x-api-key: your-api-key-here" \
-d '[
  {"id": "test-002", "data": "Bulk Insert 1", "user": "Bob"},
  {"id": "test-003", "data": "Bulk Insert 2", "user": "Charlie"}
]'
```

---

## **📌 Step 7: Event-Driven Processing with SQS & EventBridge**
We implemented **asynchronous event processing**:
✔ **EventBridge sends notifications on new submissions**  
✔ **SQS handles queued messages for analytics processing**  
✔ **Lambda processes SQS messages and stores results in S3**  

✅ **Verified events in EventBridge & SQS**  
```sh
aws events list-rules
aws sqs receive-message --queue-url https://sqs.us-east-1.amazonaws.com/your-account-id/DataSubmissionQueue
```

---

## **📌 Step 8: Storing Processed Data in S3**
✅ **Verified S3 storage**
```sh
aws s3 ls s3://analytics-data-bucket-571600861898/analytics/
aws s3 cp s3://analytics-data-bucket-571600861898/analytics/test-001.json .
cat test-001.json
```

---

## **📌 Step 9: Removing `GET /listData` API Method**
✅ **Removed API method from Terraform**
```sh
terraform apply
```
✅ **Manually redeployed API Gateway**
```sh
aws apigateway create-deployment --rest-api-id your-api-id --stage-name prod
```

---

## **🎯 Next Steps (Optional Enhancements)**
🚀 **Automate CI/CD Pipeline**: Deploy Terraform & Lambda updates automatically  
🔹 **Enhance Security**: Use AWS WAF for API Gateway, IAM least privilege policies  
🔹 **Optimize Costs**: Enable CloudWatch log retention, DynamoDB auto-scaling  
🔹 **Set Up Alarms**: Use CloudWatch Alarms for API failures, Lambda errors  

---

## **🎉 Congratulations!** 🏆  
You’ve successfully built and deployed an **end-to-end AWS Serverless System**! 🔥🚀  
**What’s next for you? More AWS projects, scaling this system, or automation?** 😃