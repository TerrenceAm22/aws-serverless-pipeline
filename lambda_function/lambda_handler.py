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
        if event["httpMethod"] == "POST":

            # Parse request body
            body = json.loads(event["body"])

            # Check if it's a bulk insert
            if isinstance(body, list):
                return handle_bulk_insert(body, context)
            else:
                return handle_single_insert(body, context, event)
    
        if event["httpMethod"] == 'GET':
            return handle_get(event, context)
    
    except Exception as e:
        print("Error:", str(e))
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}

def handle_get(event, context):
    """
    GET requests to retrieve data from DynamoDB either by ID or all data
    """
    query_params = event.get("queryStringParameters", {})

    if query_params and "id" in query_params:
        # Retrieve specific submission by ID
        submission_id = query_params["id"]
        
        response = table.get_item(Key={"id": submission_id})
        
        if "Item" in response:
            return {"statusCode": 200, "body": json.dumps(response["Item"])}
        else:
            return {"statusCode": 404, "body": json.dumps({"error": "Submission not found"})}
    
    # If No specific ID was provided, scan and return all data
    response = table.scan()
    return {"statusCode": 200, "body": json.dumps(response["Items"])}


def handle_single_insert(body, context, event):
    """ Process a single submission """
    if "id" not in body or "data" not in body or "user" not in body:
        return {"statusCode": 400, "body": json.dumps({"error": "Missing required fields (id, data, user)"})}

    user_id = body["user"]
    submission_id = body["id"]
    submission_data = body["data"]

    # Check for prohibited words
    if any(word in submission_data.lower() for word in PROHIBITED_WORDS):
        return {"statusCode": 400, "body": json.dumps({"error": "Submission contains prohibited content"})}

    # Enforce rate limiting
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

def handle_bulk_insert(submissions, context):
    """ Process a bulk insert request """
    valid_records = []
    errors = []

    for record in submissions:
        if "id" not in record or "data" not in record or "user" not in record:
            errors.append({"error": "Missing required fields", "record": record})
            continue

        user_id = record["user"]
        submission_id = record["id"]
        submission_data = record["data"]

        # Check for prohibited words
        if any(word in submission_data.lower() for word in PROHIBITED_WORDS):
            errors.append({"error": "Prohibited content", "record": record})
            continue

        # Enforce rate limiting
        if not check_rate_limit(user_id):
            errors.append({"error": "Rate limit exceeded", "record": record})
            continue

        # Check if ID already exists
        response = table.get_item(Key={"id": submission_id})
        if "Item" in response:
            errors.append({"error": "ID already exists", "record": record})
            continue

        # Prepare metadata
        metadata = {
            "submission_time": datetime.datetime.utcnow().isoformat(),
            "processed_by": context.function_name
        }

        # Add record for batch insert
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

    # Batch insert into DynamoDB
    if valid_records:
        with table.batch_writer() as batch:
            for item in valid_records:
                batch.put_item(Item=item["PutRequest"]["Item"])

        # Publish events & send to SQS for each valid submission
        for record in valid_records:
            data = record["PutRequest"]["Item"]
            publish_to_eventbridge(data["id"], data["user"])
            send_to_sqs(data["id"], data["user"], data["data"])

    response_msg = {"message": "Bulk insert complete"}
    if errors:
        response_msg["errors"] = errors

    return {"statusCode": 200, "body": json.dumps(response_msg)}

def check_rate_limit(user_id):
    """ Check if user has exceeded 3 submissions per minute """
    current_time = int(time.time())
    one_min_ago = current_time - 60

    # Retrieve the user's submission timestamps
    response = rate_limit_table.get_item(Key={"user_id": user_id})
    timestamps = response.get("Item", {}).get("timestamps", [])

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
