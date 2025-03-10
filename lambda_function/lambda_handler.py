import json
import boto3
import os
import time
import datetime

# Initialize AWS resources
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["DYNAMODB_TABLE"])
event_bridge = boto3.client("events")
sqs = boto3.client("sqs")

# Configuration
PROHIBITED_WORDS = ["spam", "fraud", "malicious"]
SUBMISSION_LIMIT = 3  # Max submissions per user per minute
RATE_LIMIT_TABLE = os.environ["RATE_LIMIT_TABLE"]
EVENT_BUS_NAME = os.environ["EVENT_BUS_NAME"]
SQS_QUEUE_URL = os.environ["SQS_QUEUE_URL"]

# Initialize rate limit table
rate_limit_table = dynamodb.Table(RATE_LIMIT_TABLE)

def lambda_handler(event, context):
    try:
        print("EVENT:", event)

        # Validate HTTP method
        if event["httpMethod"] != "POST":
            return {"statusCode": 400, "body": json.dumps({"error": "Invalid HTTP method"})}

        # Parse request body
        body = json.loads(event["body"])

        # Validate required fields
        if "id" not in body or "data" not in body or "user" not in body:
            return {"statusCode": 400, "body": json.dumps({"error": "Missing required fields (id, data, user)"})}

        user_id = body["user"]
        submission_id = body["id"]
        submission_data = body["data"]

        # Check for prohibited words
        if any(word in submission_data.lower() for word in PROHIBITED_WORDS):
            return {"statusCode": 400, "body": json.dumps({"error": "Submission contains prohibited content"})}

        # Enforce rate limiting (Check user submission count)
        if not check_rate_limit(user_id):
            return {"statusCode": 429, "body": json.dumps({"error": "Rate limit exceeded (3 submissions per minute)"})}

        # Check if ID already exists
        response = table.get_item(Key={"id": submission_id})
        if "Item" in response:
            return {"statusCode": 400, "body": json.dumps({"error": "ID already exists"})}

        # Process and store submission in DynamoDB
        metadata = {
            "submission_time": datetime.datetime.utcnow().isoformat(),
            "submission_source": event["headers"].get("User-Agent", "Unknown"),
            "processed_by": context.function_name
        }

        table.put_item(Item={
            "id": submission_id,
            "data": submission_data,
            "user": user_id,
            "metadata": metadata
        })

        # Publish event to EventBridge
        publish_to_eventbridge(submission_id, user_id)

        # Send message to SQS queue
        send_to_sqs(submission_id, user_id, submission_data)

        return {"statusCode": 200, "body": json.dumps({"message": "Data submitted successfully"})}

    except Exception as e:
        print("Error:", str(e))
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}


def check_rate_limit(user_id):
    """ Check if user has exceeded 3 submissions per minute """
    current_time = int(time.time())
    one_min_ago = current_time - 60

    # Retrieve the user's submission timestamps
    response = rate_limit_table.get_item(Key={"user_id": user_id})
    if "Item" in response:
        timestamps = response["Item"].get("timestamps", [])
        # Remove timestamps older than 60 seconds
        timestamps = [t for t in timestamps if t > one_min_ago]

        if len(timestamps) >= SUBMISSION_LIMIT:
            return False  # Rate limit exceeded

    # Update rate limit table
    timestamps.append(current_time)
    rate_limit_table.put_item(Item={"user_id": user_id, "timestamps": timestamps})

    return True


def publish_to_eventbridge(submission_id, user_id):
    """ Publish an event to EventBridge """
    event = {
        "Source": "dataProcessor.lambda",
        "DetailType": "DataSubmission",
        "Detail": json.dumps({
            "submission_id": submission_id,
            "user_id": user_id,
            "timestamp": datetime.datetime.utcnow().isoformat()
        }),
        "EventBusName": EVENT_BUS_NAME
    }
    event_bridge.put_events(Entries=[event])


def send_to_sqs(submission_id, user_id, submission_data):
    """ Send message to SQS queue """
    message = {
        "submission_id": submission_id,
        "user_id": user_id,
        "submission_data": submission_data
    }
    sqs.send_message(QueueUrl=SQS_QUEUE_URL, MessageBody=json.dumps(message))
