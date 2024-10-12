import json
import boto3
from decimal import Decimal
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

client = boto3.client('dynamodb')
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table('http-crud-tutorial-items')
tableName = 'http-crud-tutorial-items'

def lambda_handler(event, context):
    logger.info(f"Event: {json.dumps(event)}")
    body = {}
    statusCode = 200
    headers = {
        "Content-Type": "application/json"
    }
    try:
        # Intenta obtener routeKey del evento, o usa una combinación de httpMethod y resource
        route_key = event.get('routeKey')
        if not route_key:
            http_method = event.get('httpMethod')
            resource = event.get('resource')
            if http_method and resource:
                route_key = f"{http_method} {resource}"
            else:
                logger.error(f"Unable to determine route. Event structure: {json.dumps(event)}")
                raise ValueError("Unable to determine route from event")

        if route_key == "DELETE /items/{id}":
            table.delete_item(
                Key={'id': event['pathParameters']['id']})
            body = f"Deleted item {event['pathParameters']['id']}"
        elif route_key == "GET /items/{id}":
            response = table.get_item(
                Key={'id': event['pathParameters']['id']})
            item = response.get("Item")
            if item:
                body = [{'price': float(item['price']), 'id': item['id'], 'name': item['name']}]
            else:
                statusCode = 404
                body = "Item not found"
        elif route_key == "GET /items":
            response = table.scan()
            items = response.get("Items", [])
            body = []
            for item in items:
                body.append({'price': float(item['price']), 'id': item['id'], 'name': item['name']})
        elif route_key == "PUT /items":
            requestJSON = json.loads(event['body'])
            table.put_item(
                Item={
                    'id': requestJSON['id'],
                    'price': Decimal(str(requestJSON['price'])),
                    'name': requestJSON['name']
                })
            body = f"Put item {requestJSON['id']}"
        else:
            raise ValueError(f"Unsupported route: {route_key}")
    except KeyError as e:
        logger.error(f"KeyError: {str(e)}")
        statusCode = 400
        body = f"Bad request: {str(e)}"
    except ValueError as e:
        logger.error(f"ValueError: {str(e)}")
        statusCode = 400
        body = str(e)
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        statusCode = 500
        body = f"Unexpected error: {str(e)}"
    
    logger.info(f"Response: statusCode: {statusCode}, body: {body}")
    return {
        "statusCode": statusCode,
        "headers": headers,
        "body": json.dumps(body)
    }