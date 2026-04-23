import boto3
import json
import urllib.request

ssm = boto3.client('ssm', region_name='us-west-1')
cognito = boto3.client('cognito-idp', region_name='us-west-1')

USER_POOL_CLIENT_ID = "<your_cognito_client_id>"
API_BASE = "https://<your-api-domain>/api/v1"

def get_access_token():
    param = ssm.get_parameter(Name='/gc/lambda/refresh-token', WithDecryption=True)
    refresh_token = param['Parameter']['Value']

    response = cognito.initiate_auth(
        AuthFlow='REFRESH_TOKEN_AUTH',
        AuthParameters={'REFRESH_TOKEN': refresh_token},
        ClientId=USER_POOL_CLIENT_ID
    )
    return response['AuthenticationResult']['AccessToken']

def post_listing(access_token, payload):
    data = json.dumps(payload).encode('utf-8')
    req = urllib.request.Request(
        f"{API_BASE}/listings",
        data=data,
        headers={
            'Content-Type': 'application/json',
            'Authorization': f'Bearer {access_token}'
        },
        method='POST'
    )
    with urllib.request.urlopen(req) as res:
        return json.loads(res.read())

def handler(event, context):
    token = get_access_token()

    offer = { ... }   # your OFFER payload
    request = { ... } # your REQUEST payload

    post_listing(token, offer)
    post_listing(token, request)
