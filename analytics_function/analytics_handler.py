import json
import boto3
import os
import datetime

# Initialize AWS resources
s3 = boto3.client("s3")
dynamodb = boto3.resource("dynamodb")

# Environment Variables
S3_BUCKET_NAME = os.environ.get("ANALYTICS_BUCKET")
DYNAMODB_TABLE = os.environ.get("ANALYTICS_TABLE")

def lambda_handler(event, context):
    try:
        print("Received event:", json.dumps(event, indent=2))

        # If triggered by SQS, extract records
        if "Records" in event:
            for record in event["Records"]:
                process_submission(json.loads(record["body"]))

        # If triggered by EventBridge
        elif "detail" in event:
            process_submission(event["detail"])

        return {"statusCode": 200, "body": json.dumps({"message": "Analytics processed successfully"})}

    except Exception as e:
        print("Error processing analytics:", str(e))
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}

def process_submission(submission):
    """ Process the submission and store analytics data """
    submission_id = submission.get("submission_id", "unknown")
    user_id = submission.get("user_id", "unknown")
    submission_data = submission.get("data", "unknown")
    timestamp = submission.get("timestamp", datetime.datetime.utcnow().isoformat())

    # Create analytics record
    analytics_record = {
        "submission_id": submission_id,
        "user_id": user_id,
        "data": submission_data,
        "processed_at": datetime.datetime.utcnow().isoformat()
    }

    # Store in S3
    store_in_s3(submission_id, analytics_record)

    # Store in DynamoDB
    store_in_dynamodb(submission_id, analytics_record)

def store_in_s3(submission_id, analytics_record):
    """ Store analytics data in S3 with error handling """
    try:
        response = s3.put_object(
            Bucket=S3_BUCKET_NAME,
            Key=f"analytics/{submission_id}.json",
            Body=json.dumps(analytics_record),
            ContentType="application/json"
        )
        print(f"✅ Stored analytics data in S3: {submission_id}")
        return response

    except Exception as e:
        print(f"❌ Failed to store in S3: {str(e)}")
        return None

def store_in_dynamodb(submission_id, analytics_record):
    """ Store analytics data in DynamoDB """
    table = dynamodb.Table(DYNAMODB_TABLE)
    table.put_item(Item=analytics_record)
    print(f"Stored analytics data in DynamoDB: {submission_id}")
