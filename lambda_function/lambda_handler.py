import json
import boto3
import os
import time
import datetime

# Initialize AWS resources
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["DYNAMODB_TABLE"])
rate_limit_table = dynamodb.Table(os.environ["RATE_LIMIT_TABLE"])

event_bridge = boto3.client("events")
sqs = boto3.client("sqs")
sns = boto3.client("sns") 

# Configuration
PROHIBITED_WORDS = ["spam", "fraud", "malicious"]
SUBMISSION_LIMIT = 3
EVENT_BUS_NAME = os.environ["EVENT_BUS_NAME"]
SQS_QUEUE_URL = os.environ["SQS_QUEUE_URL"]
SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]  

def lambda_handler(event, context):
    try:
        print("EVENT:", event)

        if event["httpMethod"] == "POST":
            body = json.loads(event["body"])
            if isinstance(body, list):
                return handle_bulk_insert(body, context)
            else:
                return handle_single_insert(body, context, event)

        if event["httpMethod"] == "GET":
            return handle_get(event, context)

    except Exception as e:
        print("Error:", str(e))
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}

def handle_get(event, context):
    query_params = event.get("queryStringParameters", {})

    if query_params and "id" in query_params:
        submission_id = query_params["id"]
        response = table.get_item(Key={"id": submission_id})
        if "Item" in response:
            return {"statusCode": 200, "body": json.dumps(response["Item"])}
        else:
            return {"statusCode": 404, "body": json.dumps({"error": "Submission not found"})}

    response = table.scan()
    return {"statusCode": 200, "body": json.dumps(response["Items"])}

def handle_single_insert(body, context, event):
    if "id" not in body or "data" not in body or "user" not in body:
        return {"statusCode": 400, "body": json.dumps({"error": "Missing required fields (id, data, user)"})}

    user_id = body["user"]
    submission_id = body["id"]
    submission_data = body["data"]

    if any(word in submission_data.lower() for word in PROHIBITED_WORDS):
        return {"statusCode": 400, "body": json.dumps({"error": "Submission contains prohibited content"})}

    if not check_rate_limit(user_id):
        return {"statusCode": 429, "body": json.dumps({"error": "Rate limit exceeded (3 submissions per minute)"})}

    response = table.get_item(Key={"id": submission_id})
    if "Item" in response:
        return {"statusCode": 400, "body": json.dumps({"error": "ID already exists"})}

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

    publish_to_eventbridge(submission_id, user_id)
    send_to_sqs(submission_id, user_id, submission_data)

    # Publish to SNS
    sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject=" New Submission Received",
        Message=f"User '{user_id}' submitted item '{submission_id}' at {metadata['submission_time']}"
    )

    return {"statusCode": 200, "body": json.dumps({"message": "Data submitted successfully"})}

def handle_bulk_insert(submissions, context):
    valid_records = []
    errors = []

    for record in submissions:
        if "id" not in record or "data" not in record or "user" not in record:
            errors.append({"error": "Missing required fields", "record": record})
            continue

        user_id = record["user"]
        submission_id = record["id"]
        submission_data = record["data"]

        if any(word in submission_data.lower() for word in PROHIBITED_WORDS):
            errors.append({"error": "Prohibited content", "record": record})
            continue

        if not check_rate_limit(user_id):
            errors.append({"error": "Rate limit exceeded", "record": record})
            continue

        response = table.get_item(Key={"id": submission_id})
        if "Item" in response:
            errors.append({"error": "ID already exists", "record": record})
            continue

        metadata = {
            "submission_time": datetime.datetime.utcnow().isoformat(),
            "processed_by": context.function_name
        }

        valid_records.append({
            "PutRequest": {
                "Item": {
                    "id": submission_id,
                    "data": submission_data,
                    "user": user_id,
                    "metadata": metadata
                }
            }
        })

    if valid_records:
        with table.batch_writer() as batch:
            for item in valid_records:
                batch.put_item(Item=item["PutRequest"]["Item"])

        for record in valid_records:
            data = record["PutRequest"]["Item"]
            publish_to_eventbridge(data["id"], data["user"])
            send_to_sqs(data["id"], data["user"], data["data"])

    return {"statusCode": 200, "body": json.dumps({
        "message": "Bulk insert complete",
        "errors": errors if errors else None
    })}

def check_rate_limit(user_id):
    current_time = int(time.time())
    one_min_ago = current_time - 60

    response = rate_limit_table.get_item(Key={"user_id": user_id})
    timestamps = response.get("Item", {}).get("timestamps", [])
    timestamps = [t for t in timestamps if t > one_min_ago]

    if len(timestamps) >= SUBMISSION_LIMIT:
        return False

    timestamps.append(current_time)
    rate_limit_table.put_item(Item={"user_id": user_id, "timestamps": timestamps})
    return True

def publish_to_eventbridge(submission_id, user_id):
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
    message = {
        "submission_id": submission_id,
        "user_id": user_id,
        "submission_data": submission_data
    }
    sqs.send_message(QueueUrl=SQS_QUEUE_URL, MessageBody=json.dumps(message))
