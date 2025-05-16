import json
import os
import logging
import boto3
from botocore.exceptions import ClientError
import urllib3

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
s3_client = boto3.client('s3')
http = urllib3.PoolManager()

scalr_host = os.environ['SCALR_HOSTNAME']
api_url = f"https://{scalr_host}/api/iacp/v3"

def get_scalr_headers():
    """Get headers for Scalr API requests."""
    return {
        'Authorization': f'Bearer {os.environ["SCALR_TOKEN"]}',
        'Content-Type': 'application/vnd.api+json'
    }

def save_state_to_s3(state_data, environment_name, workspace_name, state_id):
    """Save state data to S3 bucket with the structure: {environment}/{workspace}/{state_id}.json"""
    try:
        bucket_name = os.environ['AWS_BUCKET']
        key = f"{environment_name}/{workspace_name}/{state_id}.json"
        
        s3_client.put_object(
            Bucket=bucket_name,
            Key=key,
            Body=json.dumps(state_data),
            ServerSideEncryption='AES256'
        )
        logger.info(f"Successfully saved state to S3: {key}")
        return True
    except ClientError as e:
        logger.error(f"Error saving to S3: {str(e)}")
        raise

def _call_scalr(route: str, params: dict = None) -> dict:
    url = f"{api_url}/{route}"
    if params:
        # Convert params to query string
        query_string = '&'.join([f"{k}={v}" for k, v in params.items()])
        url = f"{url}?{query_string}"
    
    response = http.request(
        'GET',
        url,
        headers=get_scalr_headers()
    )
    
    if response.status != 200:
        raise Exception(f"API call failed with status {response.status}: {response.data.decode('utf-8')}")
    
    return json.loads(response.data.decode('utf-8'))

def get_scalr_state_version(run_id):
    """Get the latest state version from Scalr API."""
    try:
        run = _call_scalr(f"runs/{run_id}")
        workspace_id = run["data"]["relationships"]["workspace"]["data"]["id"]

        state_versions = _call_scalr("state-versions", {
            'filter[workspace]': workspace_id,
            'filter[run]': run_id,
            'page[size]': 1,
        })

        if not state_versions.get('data'):
            logger.warning(f"No state versions found for run {run_id}")
            return None
            
        # Get the state version and included data
        state_version = state_versions['data'][0]

        # Get the download URL for the state file
        download_url = state_version['links']['download']
        
        # Download the state file
        state_response = http.request('GET', download_url)
        if state_response.status != 200:
            raise Exception(f"Failed to download state file: {state_response.data.decode('utf-8')}")
        
        return {
            'state_version': state_version,
            'state_data': json.loads(state_response.data.decode('utf-8')),
            'state_id': state_version['id']
        }
    except Exception as e:
        logger.error(f"Error fetching state version: {str(e)}")
        raise

def lambda_handler(event, context):
    """Main Lambda handler function."""
    try:
        logger.info(f"Received event: {json.dumps(event)}")
        
        # Extract information from the event
        event_detail = event['detail']['event']
        run_id = event_detail['run-id']
        environment_name = event_detail['environment']
        workspace_name = event_detail['workspace']
        
        # Get state version from Scalr
        state_data = get_scalr_state_version(run_id)
        if not state_data:
            return {
                'statusCode': 404,
                'body': json.dumps({
                    'message': 'No state version found',
                    'run_id': run_id
                })
            }
        
        # Save state to S3 with the new path structure
        save_state_to_s3(
            state_data['state_data'],
            environment_name,
            workspace_name,
            state_data['state_id']
        )

        print(f"State file of the workspace '{workspace_name}' ('{environment_name}') backed up successfully")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Successfully processed state version',
                'run_id': run_id,
                'state_id': state_data['state_id'],
                'environment': environment_name,
                'workspace': workspace_name
            })
        }
        
    except Exception as e:
        logger.error(f"Error processing event: {str(e)}")
        raise
