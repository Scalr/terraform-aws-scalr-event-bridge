import functools
import json
import logging
import os

from urllib import parse, request

logger = logging.getLogger()
logger.setLevel(logging.INFO)

scalr_hostname = os.environ['SCALR_HOSTNAME']
scalr_token = os.environ['SCALR_TOKEN']
scalr_tags = os.environ['SCALR_TAGS']

headers = {
    'Authorization': f'Bearer {scalr_token}',
    'Content-Type': 'application/vnd.api+json'
}

def exception_handler(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        try:
            return func(*args, **kwargs)
        except Exception as e:
            return {
                'statusCode': 400,
                'body': json.dumps(e, indent=2)
            }

    return wrapper

def _read_response(response):
    response_data = response.read().decode()
    json_data = json.loads(response_data)
    return json_data


def post(route: str, data: dict):
    url = f"https://{scalr_hostname}/api/iacp/v3/{route}"
    r = request.Request(url, headers=headers, data=json.dumps(data).encode(), method='POST')

    with request.urlopen(r) as response:
        json_data = _read_response(response)

        if response.status not in [200, 201]:
            raise Exception(json_data)

        return json_data


def get(route: str, filters: dict = None):
    filters = f"?{parse.urlencode(filters)}" if filters else ""
    url = f"https://{scalr_hostname}/api/iacp/v3/{route}{filters}"
    r = request.Request(url, headers=headers, method='GET')

    with request.urlopen(r) as response:
        json_data = _read_response(response)

        if response.status != 200:
            raise Exception(json_data)

        return json_data


@exception_handler
def lambda_handler(event, context):
    logger.info("Received event from EventBridge: %s", json.dumps(event, indent=2))

    tags = get("tags", {"filter[name]": f"in:{scalr_tags}"})
    if not tags["data"]:
        raise Exception({f"Missing tag '{scalr_tags}'"})

    workspaces = get("workspaces", {"filter[tag]": tags['data'][0]['id'], 'filter[environment-type]': 'production'})

    if not workspaces["data"]:
        raise Exception({"No workspaces that match tag 'VPC' and 'production' environment type"})

    for workspace in workspaces['data']:
        workspace_id = workspace['id']
        logger.info("Triggering updating VPC rules in: %s (%s)", workspace['attributes']['name'], workspace_id)

        payload = {
            "data": {
                "relationships": {
                    "workspace": {
                        "data": {
                            "type": "workspaces",
                            "id": workspace_id
                        }
                    }
                },
                "type": "runs"
            }
        }

        post(f"runs", payload)

    return {
        'statusCode': 200,
        'body': json.dumps('Event processed successfully!')
    }
