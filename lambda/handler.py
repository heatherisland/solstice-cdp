import json, os, boto3, datetime

MAX_OBJECTS = 75
IDENTIFIERS = {"external_id", "user_alias", "braze_id", "email", "phone"}
s3 = boto3.client("s3")

def handler(event, context):
    if event["headers"].get("authorization") != f"Bearer {os.environ['FAKE_BRAZE_KEY']}":
        return {"statusCode": 401, "body": json.dumps({"message": "invalid api key"})}

    body = json.loads(event.get("body") or "{}")
    objs = body.get("attributes", []) + body.get("events", []) + body.get("purchases", [])

    if len(objs) > MAX_OBJECTS:
        return {"statusCode": 429,
                "body": json.dumps({"message": f"{len(objs)} objects exceeds limit of {MAX_OBJECTS}"})}

    errors = [i for i, o in enumerate(objs) if not (IDENTIFIERS & o.keys())]
    if errors:
        return {"statusCode": 400,
                "body": json.dumps({"message": "no identifier", "errors": errors})}

    key = f"received/{datetime.datetime.utcnow():%Y/%m/%d/%H%M%S_%f}.json"
    s3.put_object(Bucket=os.environ["BUCKET"], Key=key, Body=json.dumps(body))

    return {"statusCode": 201,
            "body": json.dumps({"message": "success", "attributes_processed": len(objs)})}
